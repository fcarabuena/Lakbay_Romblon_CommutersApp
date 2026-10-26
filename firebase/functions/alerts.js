'use strict';

// Pure logic for advisory push alerts, kept free of Firebase so it can be
// unit tested (see test/alerts.test.js).
//
// Topic names mirror packages/core/lib/src/alerts/alert_topics.dart:
//   adv_all_<lang>               everyone who chose "All of Romblon"
//   adv_general_<lang>           port subscribers, for advisories naming no port
//   adv_port_<portId>_<lang>     port subscribers, per chosen port

const ALERT_SEVERITIES = ['caution', 'suspended'];
const LANGUAGES = ['en', 'fil'];

const SEVERITY_LABEL = {
  en: { caution: 'Caution', suspended: 'Suspended' },
  fil: { caution: 'Mag-ingat', suspended: 'Suspendido' },
};

function topicSafe(id) {
  return String(id).replace(/[^a-zA-Z0-9\-_.~%]/g, '-');
}

/** Whether an advisory document should alert people right now. */
function qualifies(doc, nowMs) {
  if (!doc || doc.deleted === true) return false;
  if (!ALERT_SEVERITIES.includes(doc.severity)) return false;
  if (doc.validUntil && Date.parse(doc.validUntil) <= nowMs) return false;
  return true;
}

/**
 * Alert when an advisory newly becomes alert-worthy (published, raised to
 * caution or suspension, or restored after deletion), or escalates from
 * caution to suspended. Plain edits of a live advisory do not re-alert.
 */
function shouldNotify(before, after, nowMs) {
  if (!qualifies(after, nowMs)) return false;
  if (!qualifies(before, nowMs)) return true;
  return before.severity === 'caution' && after.severity === 'suspended';
}

/** Topics to send to, given the ports the advisory touches. */
function topicsFor(portIds) {
  const ports = [...new Set(portIds)].sort();
  const topics = [];
  for (const lang of LANGUAGES) {
    topics.push(`adv_all_${lang}`);
    if (ports.length === 0) {
      topics.push(`adv_general_${lang}`);
    } else {
      for (const p of ports) topics.push(`adv_port_${topicSafe(p)}_${lang}`);
    }
  }
  return topics;
}

function text(localized, lang) {
  if (typeof localized === 'string') return localized;
  if (!localized) return '';
  return localized[lang] || localized.en || '';
}

function truncate(s, max) {
  return s.length <= max ? s : `${s.slice(0, max - 1)}…`;
}

/** FCM messages, one per topic, in the topic's language. */
function buildMessages(advisoryId, advisory, portIds) {
  return topicsFor(portIds).map((topic) => {
    const lang = topic.endsWith('_fil') ? 'fil' : 'en';
    const title = `${SEVERITY_LABEL[lang][advisory.severity]}: ${text(advisory.title, lang)}`;
    return {
      topic,
      notification: {
        title: truncate(title, 100),
        body: truncate(text(advisory.message, lang), 200),
      },
      data: { advisoryId },
      android: {
        priority: 'high',
        // Same tag per advisory: a phone on several topics shows it once.
        notification: { tag: `advisory-${advisoryId}` },
      },
    };
  });
}

module.exports = { qualifies, shouldNotify, topicsFor, buildMessages, topicSafe };
