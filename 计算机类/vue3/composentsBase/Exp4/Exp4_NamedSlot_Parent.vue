<template>
  <h3>具名插槽</h3>
  <Poetry>
    <template v-slot:title>
      <h3>行路难·其一</h3>
    </template>

    <template #author>
      <p>李白</p>
    </template>

    <template #default>
      <div>行路难，行路难，多岐路，今安在？</div>
      <div>长风破浪会有时，直挂云帆济沧海。</div>
    </template>
  </Poetry>
</template>

<script setup>
import Poetry from './Exp4_NamedSlot_Child.vue'
</script>
