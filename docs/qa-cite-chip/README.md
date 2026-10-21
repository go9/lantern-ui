# Citation chip verification

Reproduce: start `MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs`,
then run `QA_SHOTS=docs/qa-cite-chip node test/qa/cite_chip.mjs`.
Set `CHROME_PATH` if Chromium is not at `/usr/bin/chromium`.

The script checks native Tab order, Enter and Space activation, server-selected
pressed state and preview content for file/ticket/memory, focus retention after
patching, no horizontal overflow, and zero transition with reduced motion.
Four captures cover light/dark at 960px and 390px; memory is selected and focused.

- [Desktop light](960-light.png)
- [Desktop dark](960-dark.png)
- [Mobile light](390-light.png)
- [Mobile dark](390-dark.png)
