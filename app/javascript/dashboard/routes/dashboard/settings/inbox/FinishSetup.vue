<script setup>
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import QRCode from 'qrcode';
import EmptyState from '../../../../components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const { t } = useI18n();
const route = useRoute();
const store = useStore();

// eslint-disable-next-line no-console
console.log('==================================');
// eslint-disable-next-line no-console
console.log(
  '[BAILEYS DEBUG] FinishSetup.vue loaded - NEW VERSION with debugging'
);
// eslint-disable-next-line no-console
console.log('[BAILEYS DEBUG] Inbox ID from route:', route.params.inbox_id);
// eslint-disable-next-line no-console
console.log('==================================');

const qrCodes = reactive({
  whatsapp: '',
  messenger: '',
  telegram: '',
});

const baileysQRCode = ref('');
const baileysConnectionStatus = ref('');
const qrPollingInterval = ref(null);

const currentInbox = computed(() => {
  const inbox = store.getters['inboxes/getInbox'](route.params.inbox_id);
  // eslint-disable-next-line no-console
  console.log(
    '[BAILEYS DEBUG] currentInbox computed - provider:',
    inbox?.provider,
    'has provider_connection_data:',
    !!inbox?.provider_connection_data
  );
  return inbox;
});

const isBaileysProvider = computed(() => {
  const isBaileys = currentInbox.value?.provider === 'baileys';
  // eslint-disable-next-line no-console
  console.log('[BAILEYS DEBUG] isBaileysProvider computed:', isBaileys);
  return isBaileys;
});

// Use useInbox composable with the inbox ID
const {
  isAWhatsAppCloudChannel,
  isATwilioChannel,
  isASmsInbox,
  isALineChannel,
  isAnEmailChannel,
  isAWhatsAppChannel,
  isAFacebookInbox,
  isATelegramChannel,
  isATwilioWhatsAppChannel,
} = useInbox(route.params.inbox_id);

const hasDuplicateInstagramInbox = computed(() => {
  const instagramId = currentInbox.value.instagram_id;
  const facebookInbox =
    store.getters['inboxes/getFacebookInboxByInstagramId'](instagramId);

  return (
    currentInbox.value.channel_type === INBOX_TYPES.INSTAGRAM && facebookInbox
  );
});

const shouldShowWhatsAppWebhookDetails = computed(() => {
  return (
    isAWhatsAppCloudChannel.value &&
    currentInbox.value.provider_config?.source !== 'embedded_signup'
  );
});

const isWhatsAppEmbeddedSignup = computed(() => {
  return (
    isAWhatsAppCloudChannel.value &&
    currentInbox.value.provider_config?.source === 'embedded_signup'
  );
});

const message = computed(() => {
  if (isATwilioChannel.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isASmsInbox.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isALineChannel.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isAWhatsAppCloudChannel.value && shouldShowWhatsAppWebhookDetails.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isAnEmailChannel.value && !currentInbox.value.provider) {
    return t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE');
  }

  if (currentInbox.value.web_widget_script) {
    return t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
  }

  if (isWhatsAppEmbeddedSignup.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION'
    )}`;
  }

  return t('INBOX_MGMT.FINISH.MESSAGE');
});

async function generateQRCode(platform, identifier) {
  if (!identifier || !identifier.trim()) {
    // eslint-disable-next-line no-console
    console.warn(`Invalid identifier for ${platform} QR code`);
    return;
  }

  try {
    const platformUrls = {
      whatsapp: id => `https://wa.me/${id}`,
      messenger: id => `https://m.me/${id}`,
      telegram: id => `https://t.me/${id}`,
    };

    const url = platformUrls[platform](identifier);
    const qrDataUrl = await QRCode.toDataURL(url);
    qrCodes[platform] = qrDataUrl;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(`Error generating ${platform} QR code:`, error);
    qrCodes[platform] = '';
  }
}

async function fetchBaileysConnection() {
  // eslint-disable-next-line no-console
  console.log(
    '[BAILEYS DEBUG] fetchBaileysConnection called, isBaileysProvider:',
    isBaileysProvider.value
  );

  if (!isBaileysProvider.value) {
    // eslint-disable-next-line no-console
    console.log(
      '[BAILEYS DEBUG] fetchBaileysConnection - early return, not Baileys provider'
    );
    return;
  }

  try {
    // eslint-disable-next-line no-console
    console.log(
      '[BAILEYS DEBUG] Fetching inbox data for ID:',
      route.params.inbox_id
    );

    // Refresh inbox data to get latest provider_connection_data
    await store.dispatch('inboxes/get', route.params.inbox_id);

    // eslint-disable-next-line no-console
    console.log('[BAILEYS DEBUG] Current inbox:', currentInbox.value);
    // eslint-disable-next-line no-console
    console.log('[BAILEYS DEBUG] Provider:', currentInbox.value?.provider);
    // eslint-disable-next-line no-console
    console.log(
      '[BAILEYS DEBUG] Provider connection data:',
      currentInbox.value?.provider_connection_data
    );

    const connectionData = currentInbox.value?.provider_connection_data;
    if (connectionData) {
      // eslint-disable-next-line no-console
      console.log(
        '[BAILEYS DEBUG] Connection status:',
        connectionData.connection
      );
      // eslint-disable-next-line no-console
      console.log(
        '[BAILEYS DEBUG] QR code URL length:',
        connectionData.qr_data_url?.length
      );

      baileysConnectionStatus.value = connectionData.connection || '';
      baileysQRCode.value = connectionData.qr_data_url || '';

      // Stop polling if connected
      if (connectionData.connection === 'open' && qrPollingInterval.value) {
        clearInterval(qrPollingInterval.value);
        qrPollingInterval.value = null;
      }
    } else {
      // eslint-disable-next-line no-console
      console.log('[BAILEYS DEBUG] No connection data found');
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error fetching Baileys connection:', error);
  }
}

async function startBaileysPolling() {
  // eslint-disable-next-line no-console
  console.log(
    '[BAILEYS DEBUG] startBaileysPolling called, isBaileysProvider:',
    isBaileysProvider.value
  );

  if (!isBaileysProvider.value) {
    // eslint-disable-next-line no-console
    console.log(
      '[BAILEYS DEBUG] startBaileysPolling - early return, not Baileys provider'
    );
    return;
  }

  // Initial fetch
  // eslint-disable-next-line no-console
  console.log(
    '[BAILEYS DEBUG] startBaileysPolling - calling initial fetchBaileysConnection'
  );
  await fetchBaileysConnection();

  // Poll every 3 seconds for QR code updates
  // eslint-disable-next-line no-console
  console.log(
    '[BAILEYS DEBUG] startBaileysPolling - setting up 3-second polling interval'
  );
  qrPollingInterval.value = setInterval(fetchBaileysConnection, 3000);
}

async function generateQRCodes() {
  // eslint-disable-next-line no-console
  console.log(
    '[BAILEYS DEBUG] generateQRCodes called, has currentInbox:',
    !!currentInbox.value,
    'isBaileys:',
    isBaileysProvider.value
  );

  if (!currentInbox.value) {
    // eslint-disable-next-line no-console
    console.log('[BAILEYS DEBUG] generateQRCodes - early return, no inbox');
    return;
  }

  // For Baileys provider, use the QR code from provider_connection_data
  if (isBaileysProvider.value) {
    // eslint-disable-next-line no-console
    console.log('[BAILEYS DEBUG] generateQRCodes - starting Baileys polling');
    await startBaileysPolling();
    return;
  }

  // WhatsApp (Cloud and Twilio) - generate wa.me QR code
  if (currentInbox.value.phone_number && isAWhatsAppChannel.value) {
    // For Twilio WhatsApp, phone_number format is "whatsapp:+1234567890"
    // Extract just the phone number part for QR code generation
    const phoneNumber = currentInbox.value.phone_number.replace(
      'whatsapp:',
      ''
    );
    await generateQRCode('whatsapp', phoneNumber);
  }

  // Facebook Messenger
  if (currentInbox.value.page_id && isAFacebookInbox.value) {
    await generateQRCode('messenger', currentInbox.value.page_id);
  }

  // Telegram
  if (isATelegramChannel.value && currentInbox.value.bot_name) {
    await generateQRCode('telegram', currentInbox.value.bot_name);
  }
}

// Watch for QR code changes
watch(baileysQRCode, (newVal, oldVal) => {
  // eslint-disable-next-line no-console
  console.log('[BAILEYS DEBUG] baileysQRCode changed:', {
    hadValue: !!oldVal,
    hasValue: !!newVal,
    length: newVal?.length,
  });
});

// Watch for connection status changes
watch(baileysConnectionStatus, (newVal, oldVal) => {
  // eslint-disable-next-line no-console
  console.log('[BAILEYS DEBUG] baileysConnectionStatus changed:', {
    from: oldVal,
    to: newVal,
  });
});

// Watch for currentInbox changes and regenerate QR codes when available
watch(
  currentInbox,
  newInbox => {
    // eslint-disable-next-line no-console
    console.log(
      '[BAILEYS DEBUG] currentInbox watcher fired, has inbox:',
      !!newInbox
    );
    if (newInbox) {
      generateQRCodes();
    }
  },
  { immediate: true }
);

onMounted(() => {
  // eslint-disable-next-line no-console
  console.log('[BAILEYS DEBUG] Component mounted, calling generateQRCodes');
  generateQRCodes();
});

onUnmounted(() => {
  if (qrPollingInterval.value) {
    clearInterval(qrPollingInterval.value);
    qrPollingInterval.value = null;
  }
});
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <DuplicateInboxBanner
      v-if="hasDuplicateInstagramInbox"
      :content="$t('INBOX_MGMT.ADD.INSTAGRAM.NEW_INBOX_SUGGESTION')"
    />
    <EmptyState
      :title="$t('INBOX_MGMT.FINISH.TITLE')"
      :message="message"
      :button-text="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
    >
      <div class="w-full text-center">
        <div class="my-4 mx-auto max-w-[70%]">
          <woot-code
            v-if="currentInbox.web_widget_script"
            :script="currentInbox.web_widget_script"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isATwilioWhatsAppChannel"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div
          v-if="shouldShowWhatsAppWebhookDetails"
          class="w-[50%] max-w-[50%] ml-[25%]"
        >
          <p class="mt-8 font-medium text-slate-700 dark:text-slate-200">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL') }}
          </p>
          <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
          <p class="mt-8 font-medium text-n-slate-11">
            {{
              $t(
                'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_VERIFICATION_TOKEN'
              )
            }}
          </p>
          <woot-code
            lang="html"
            :script="currentInbox.provider_config.webhook_verify_token"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isALineChannel"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isASmsInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div
          v-if="isAnEmailChannel && !currentInbox.provider"
          class="w-[50%] max-w-[50%] ml-[25%]"
        >
          <woot-code lang="html" :script="currentInbox.forward_to_email" />
        </div>
        <!-- Baileys WhatsApp QR Code (Device Linking) -->
        <div
          v-if="isBaileysProvider"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <div v-if="baileysQRCode && baileysConnectionStatus !== 'open'">
            <p class="mt-2 mb-4 text-sm text-n-slate-9 text-center">
              {{ $t('INBOX_MGMT.FINISH.BAILEYS_QR_INSTRUCTION') }}
            </p>
            <div class="rounded-lg shadow outline-1 outline-n-strong outline">
              <img
                :src="baileysQRCode"
                alt="Baileys WhatsApp QR Code"
                class="rounded-lg size-48"
              />
            </div>
          </div>
          <div
            v-else-if="baileysConnectionStatus === 'open'"
            class="text-center"
          >
            <p class="text-sm text-green-600 font-medium">
              {{ $t('INBOX_MGMT.FINISH.BAILEYS_CONNECTED') }}
            </p>
          </div>
          <div v-else class="text-center">
            <p class="text-sm text-n-slate-9">
              {{ $t('INBOX_MGMT.FINISH.BAILEYS_WAITING') }}
            </p>
          </div>
        </div>

        <!-- Other WhatsApp Providers QR Code (wa.me link) -->
        <div
          v-if="isAWhatsAppChannel && !isBaileysProvider && qrCodes.whatsapp"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION') }}
          </p>
          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.whatsapp"
              alt="WhatsApp QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div
          v-if="isAFacebookInbox && qrCodes.messenger"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.MESSENGER_QR_INSTRUCTION') }}
          </p>
          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.messenger"
              alt="Messenger QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div
          v-if="isATelegramChannel && qrCodes.telegram"
          class="flex flex-col gap-4 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.TELEGRAM_QR_INSTRUCTION') }}
          </p>

          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.telegram"
              alt="Telegram QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div class="flex gap-2 justify-center mt-4">
          <router-link
            :to="{
              name: 'settings_inbox_show',
              params: { inboxId: $route.params.inbox_id },
            }"
          >
            <NextButton
              outline
              slate
              :label="$t('INBOX_MGMT.FINISH.MORE_SETTINGS')"
            />
          </router-link>
          <router-link
            :to="{
              name: 'inbox_dashboard',
              params: { inboxId: $route.params.inbox_id },
            }"
          >
            <NextButton
              solid
              teal
              :label="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
            />
          </router-link>
        </div>
      </div>
    </EmptyState>
  </div>
</template>
