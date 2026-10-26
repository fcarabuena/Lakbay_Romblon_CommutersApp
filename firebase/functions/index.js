'use strict';

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

const { shouldNotify, buildMessages } = require('./alerts');

initializeApp();

// Must match the Firestore database location (see docs/firebase-setup.md).
const REGION = 'asia-southeast1';

/**
 * Sends a push alert when a caution or suspension advisory is published.
 * Travellers opt in from Settings; see alerts.js for who gets what.
 */
exports.advisoryAlerts = onDocumentWritten(
  { document: 'advisories/{advisoryId}', region: REGION, retry: false },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const id = event.params.advisoryId;
    if (!shouldNotify(before, after, Date.now())) return;

    // Voyages named by the advisory alert the ports they call at.
    const ports = new Set(after.affectedPortIds || []);
    const voyageIds = after.affectedVoyageIds || [];
    if (voyageIds.length > 0) {
      const db = getFirestore();
      const voyages = await db.getAll(...voyageIds.map((v) => db.doc(`voyages/${v}`)));
      for (const v of voyages) {
        for (const stop of v.get('stops') || []) ports.add(stop.portId);
      }
    }

    const messages = buildMessages(id, after, [...ports]);
    const result = await getMessaging().sendEach(messages);
    logger.info('Advisory alert sent', {
      advisoryId: id,
      topics: messages.length,
      failures: result.failureCount,
    });
  },
);
