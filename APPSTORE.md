# Чек-лист публикации в App Store

## Перед отправкой
- [ ] Apple Developer Program ($99/год), зарегистрированы Bundle ID (`com.katsuro.WordLock`, `.Widget`, `.Share`) и App Group
- [ ] Проверьте, что название «WordLock» свободно в App Store Connect (иначе добавьте подзаголовок или смените)
- [ ] Archive → Validate App; TestFlight на реальном устройстве
- [ ] Проверить на устройстве: кнопки виджета на заблокированном экране, Share Extension в Safari, iCloud на двух устройствах, напоминания
- [ ] Скриншоты 6.9" (и 6.5" при необходимости): «Сегодня», карточка, тест, словарь, экран блокировки с виджетом
- [ ] Страница политики конфиденциальности (шаблон ниже) и страница поддержки (можно простой GitHub Pages / Notion)
- [ ] App Privacy: «Data Not Collected»; возраст 4+; Export Compliance: нет шифрования, кроме стандартного (в Info.plist уже `false`)

## Review Notes (вставьте в App Store Connect)
> The app's main feature is a Lock Screen / Home Screen widget. To test: long-press the Lock Screen → Customize → tap the area below the clock → add "WordLock" (rectangular). Tap the eye button to reveal the translation, then tap the check / repeat button. All learning features are also available inside the app (Today tab → flashcards, quiz, typing). No account or login required.

## Описание (RU)
**WordLock — английские слова на экране блокировки.**
Каждый раз, когда берёшь телефон, перед глазами новое слово. Нажми «глаз», вспомни перевод и ответь «Знал» или «Не знал» — прямо на виджете. Умные повторения вернут слово тогда, когда пора его повторить.
• Виджеты для экрана блокировки, домашнего экрана и StandBy
• Карточки, тесты и ввод слова, озвучка и транскрипция
• 669 слов с примерами, колоды по темам, свои слова и импорт из Anki/CSV
• Серия дней, цель на день, напоминания
• Без рекламы и без сбора данных, синхронизация через iCloud

Ключевые слова: английский,слова,карточки,виджет,экран блокировки,изучение языка,словарь,запоминание,повторение,vocabulary

## Description (EN)
**WordLock — learn English words on your Lock Screen.**
Every time you pick up your phone, a new word is waiting. Tap the eye, recall the translation and answer "Knew it" or "Didn't know" right on the widget. Spaced repetition brings each word back exactly when it's time.
• Lock Screen, Home Screen and StandBy widgets
• Flashcards, quizzes and typing practice with pronunciation and IPA
• 669 words with example sentences, topic decks, your own words, Anki/CSV import
• Daily streak, goals and reminders
• No ads, no data collection, iCloud sync

Keywords: english,vocabulary,flashcards,widget,lock screen,words,learn,spaced repetition,dictionary,memorize

## Шаблон политики конфиденциальности
WordLock не собирает, не передаёт и не продаёт персональные данные. Все слова и прогресс хранятся на устройстве.
Если вы вошли в iCloud, прогресс и добавленные слова синхронизируются через вашу учётную запись iCloud (Apple). Автоперевод
выполняется на устройстве средствами Apple Translation. Контакты: <ваш e-mail>.
