import Foundation

/// Встроенный словарь Pre-Intermediate.
/// Формат строки: английское|перевод|транскрипция (US)|тема|пример.
/// Файл сгенерирован скриптом; транскрипции — CMU Pronouncing Dictionary.
enum BuiltInVocabulary {
    /// Все слова в исходном (алфавитном) порядке.
    static let all: [Card] = {
        var seen = Set<String>()
        var result = [Card]()
        for line in raw.split(separator: "\n") {
            let p = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard p.count == 5 else { continue }
            var id = "b:" + p[0].lowercased()
            if !seen.insert(id).inserted { id += "#2" }
            result.append(Card(id: id,
                               english: p[0],
                               translation: p[1],
                               ipa: p[2].isEmpty ? nil : p[2],
                               example: p[4].isEmpty ? nil : p[4],
                               topic: Topic(rawValue: p[3]) ?? .general,
                               isCustom: false,
                               addedAt: nil))
        }
        return result
    }()

    /// Порядок показа новых слов: фиксированное перемешивание (seed), чтобы не было «недели на букву A».
    static let ordered: [Card] = {
        var rng = SeededRandom(seed: 0x574F5244)
        return all.shuffled(using: &rng)
    }()

    static let byID: [String: Card] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    private static let raw = """
ability|способность|əˈbɪləˌti|general|She has the ability to learn fast.
abroad|за границей|əˈbrɔd|travel|He studies abroad.
accept|принимать|ækˈsɛpt|actions|Please accept my gift.
accident|несчастный случай|ˈæksədənt|general|There was a car accident.
account|счёт|əˈkaʊnt|work|I opened a bank account.
achieve|достигать|əˈtʃiv|actions|You can achieve your goals.
across|через|əˈkrɔs|general|We walked across the bridge.
action|действие|ˈækʃən|general|We must take action now.
active|активный|ˈæktɪv|qualities|My grandfather is very active.
activity|занятие|ækˈtɪvəti|general|Swimming is my favorite activity.
actor|актёр|ˈæktɚ|people|He is a famous actor.
actually|на самом деле|ˈækˌtʃuəli|general|I actually like this song.
add|добавлять|æd|actions|Add some sugar, please.
address|адрес|ˈæˌdrɛs|travel|What is your home address?
adult|взрослый|əˈdʌlt|people|Children must come with an adult.
advice|совет|ædˈvaɪs|general|Thanks for your advice.
afraid|испуганный|əˈfreɪd|qualities|I am afraid of dogs.
after|после|ˈæftɚ|time|We eat after the lesson.
afternoon|день|ˌæftɚˈnun|time|I have a meeting this afternoon.
again|снова|əˈɡɛn|time|Please say it again.
against|против|əˈɡɛnst|general|We play against a strong team.
age|возраст|eɪdʒ|people|What is your age?
agree|соглашаться|əˈɡri|actions|I agree with you.
air|воздух|ɛr|nature|The air is fresh here.
airport|аэропорт|ˈɛrˌpɔrt|travel|The airport is far from the city.
alive|живой|əˈlaɪv|qualities|The fish is still alive.
allow|разрешать|əˈlaʊ|actions|They don't allow dogs here.
almost|почти|ˈɔlˌmoʊst|general|I am almost ready.
alone|один|əˈloʊn|qualities|She lives alone.
already|уже|ɔlˈrɛdi|time|I have already eaten.
although|хотя|ˌɔlˈðoʊ|general|Although it was late, we kept working.
always|всегда|ˈɔlˌweɪz|time|He always arrives on time.
amazing|удивительный|əˈmeɪzɪŋ|qualities|The view is amazing.
among|среди|əˈmʌŋ|general|She is the best among us.
amount|количество|əˈmaʊnt|general|A small amount of salt is enough.
angry|злой|ˈæŋɡri|qualities|Dad is angry with me.
animal|животное|ˈænəməl|nature|A horse is a big animal.
another|другой|əˈnʌðɚ|general|Can I have another cup of tea?
answer|ответ|ˈænsɚ|work|I know the answer.
anyone|кто-нибудь|ˈɛniˌwʌn|general|Is anyone at home?
anything|что-нибудь|ˈɛniˌθɪŋ|general|Do you need anything?
anywhere|где-нибудь|ˈɛniˌwɛr|general|I can't find my keys anywhere.
apartment|квартира|əˈpɑrtmənt|home|Their apartment is on the third floor.
appear|появляться|əˈpɪr|actions|A star appeared in the sky.
apple|яблоко|ˈæpəl|food|I eat an apple every day.
apply|подавать заявку|əˈplaɪ|actions|She applied for a new job.
area|район|ˈɛriə|travel|We live in a quiet area.
argue|спорить|ˈɑrɡju|actions|They always argue about money.
arm|рука|ɑrm|health|He broke his arm.
arrive|прибывать|ɚˈaɪv|actions|The train arrives at six.
art|искусство|ɑrt|general|I love modern art.
article|статья|ˈɑrtəkəl|work|I read an interesting article.
artist|художник|ˈɑrtəst|people|The artist painted a portrait.
asleep|спящий|əˈslip|health|The baby is asleep.
attention|внимание|əˈtɛnʃən|general|Pay attention, please.
attractive|привлекательный|əˈtræktɪv|qualities|He has an attractive smile.
available|доступный|əˈveɪləbəl|qualities|Is this table available?
avoid|избегать|əˈvɔɪd|actions|Try to avoid fast food.
awake|бодрствующий|əˈweɪk|health|I was awake all night.
away|далеко|əˈweɪ|general|The station is two miles away.
baby|ребёнок|ˈbeɪbi|people|The baby is crying.
back|назад|bæk|general|Come back soon.
badly|плохо|ˈbædli|general|He slept badly.
bag|сумка|bæɡ|home|Put it in your bag.
bake|печь|beɪk|food|She bakes bread every Sunday.
ball|мяч|bɔl|home|The children play with a ball.
bank|банк|bæŋk|work|The bank closes at five.
base|основа|beɪs|general|Trust is the base of friendship.
basic|основной|ˈbeɪsɪk|qualities|He has basic English skills.
bath|ванна|bæθ|home|I take a bath every evening.
beach|пляж|bitʃ|travel|We spent the day on the beach.
beautiful|красивый|ˈbjutəfəl|qualities|What a beautiful garden!
because|потому что|bɪˈkɔz|general|I stayed home because I was sick.
become|становиться|bɪˈkʌm|actions|She wants to become a doctor.
before|до|bɪˈfɔr|time|Wash your hands before dinner.
begin|начинать|bɪˈɡɪn|actions|The film begins at eight.
believe|верить|bɪˈliv|actions|I believe you.
below|ниже|bɪˈloʊ|general|The temperature is below zero.
belong|принадлежать|bɪˈlɔŋ|actions|This book belongs to me.
best|лучший|bɛst|qualities|She is my best friend.
better|лучше|ˈbɛtɚ|qualities|I feel better today.
between|между|bɪˈtwin|general|The shop is between the bank and the cafe.
bicycle|велосипед|ˈbaɪsɪkəl|travel|I go to work by bicycle.
bill|счёт|bɪl|work|Can we have the bill, please?
bird|птица|bɝd|nature|A bird is singing in the tree.
birthday|день рождения|ˈbɝθˌdeɪ|time|Today is my birthday.
blank|пустой|blæŋk|qualities|Leave the last page blank.
block|квартал|blɑk|travel|The school is two blocks away.
boat|лодка|boʊt|travel|We crossed the lake by boat.
body|тело|ˈbɑdi|health|Exercise is good for your body.
boil|кипятить|bɔɪl|food|Boil the water for five minutes.
book|книга|bʊk|work|This book is very interesting.
boring|скучный|ˈbɔrɪŋ|qualities|The lesson was boring.
borrow|брать взаймы|ˈbɑˌroʊ|actions|Can I borrow your pen?
boss|начальник|bɑs|people|My boss is very kind.
bottle|бутылка|ˈbɑtəl|home|Bring a bottle of water.
bottom|низ|ˈbɑtəm|general|The key is at the bottom of the bag.
bowl|миска|boʊl|home|He ate a bowl of soup.
brain|мозг|breɪn|health|The brain controls the body.
branch|ветка|bræntʃ|nature|A bird sat on the branch.
brave|смелый|breɪv|qualities|The firefighter was very brave.
bread|хлеб|brɛd|food|We need fresh bread.
break|ломать|breɪk|actions|Don't break the window.
breakfast|завтрак|ˈbrɛkfəst|food|I have eggs for breakfast.
bridge|мост|brɪdʒ|travel|We crossed the old bridge.
bright|яркий|braɪt|qualities|The room is bright and sunny.
bring|приносить|brɪŋ|actions|Please bring your passport.
broken|сломанный|ˈbroʊkən|qualities|My phone is broken.
build|строить|bɪld|actions|They want to build a house.
building|здание|ˈbɪldɪŋ|travel|It is a very tall building.
business|бизнес|ˈbɪznəs|work|He runs a small business.
busy|занятый|ˈbɪzi|qualities|I'm busy right now.
button|кнопка|ˈbʌtən|home|Press the green button.
buy|покупать|baɪ|actions|I want to buy a new coat.
cafe|кафе|kəˈfeɪ|food|Let's meet at the cafe.
call|звонить|kɔl|actions|I'll call you tonight.
calm|спокойный|kɑm|qualities|Stay calm, please.
camera|камера|ˈkæmɚə|home|She bought a new camera.
camp|лагерь|kæmp|travel|We set up camp near the river.
cancel|отменять|ˈkænsəl|actions|I need to cancel my order.
capital|столица|ˈkæpətəl|travel|Paris is the capital of France.
care|забота|kɛr|general|Take care of yourself.
careful|осторожный|ˈkɛrfəl|qualities|Be careful on the road.
carry|нести|ˈkæri|actions|Can you carry this box?
case|случай|keɪs|general|In that case, we should wait.
cash|наличные|kæʃ|work|Do you pay by card or cash?
castle|замок|ˈkæsəl|travel|We visited an old castle.
catch|ловить|kætʃ|actions|Try to catch the ball.
cause|причина|kɑz|general|Smoking is a cause of many diseases.
celebrate|праздновать|ˈsɛləˌbreɪt|actions|We celebrate New Year together.
center|центр|ˈsɛntɚ|travel|The hotel is in the city center.
century|век|ˈsɛntʃɚi|time|The church was built in the 19th century.
certain|определённый|ˈsɝtən|qualities|Certain words are hard to say.
chair|стул|tʃɛr|home|Sit on that chair.
chance|шанс|tʃæns|general|Give me a chance to explain.
change|изменять|tʃeɪndʒ|actions|I want to change my job.
cheap|дешёвый|tʃip|qualities|This hotel is cheap.
check|проверять|tʃɛk|actions|Please check your email.
cheese|сыр|tʃiz|food|I like cheese sandwiches.
choose|выбирать|tʃuz|actions|Choose a color.
cinema|кинотеатр|ˈsɪnəmə|travel|We went to the cinema.
city|город|ˈsɪti|travel|London is a big city.
class|занятие|klæs|work|Our class starts at nine.
clean|чистый|klin|qualities|Keep your room clean.
clear|ясный|klɪr|qualities|The sky is clear today.
clever|умный|ˈklɛvɚ|qualities|She is a clever girl.
climb|взбираться|klaɪm|actions|We climbed the mountain.
clock|часы|klɑk|home|The clock is on the wall.
close|закрывать|kloʊs|actions|Please close the door.
clothes|одежда|kloʊðz|home|I bought new clothes.
cloud|облако|klaʊd|nature|There is a dark cloud over us.
club|клуб|klʌb|general|He joined a chess club.
coat|пальто|koʊt|home|Take your coat, it's cold.
coffee|кофе|ˈkɑfi|food|I drink coffee every morning.
cold|холодный|koʊld|qualities|The water is cold.
college|колледж|ˈkɑlɪdʒ|work|She studies at college.
comfortable|удобный|ˈkʌmfɚtəbəl|qualities|This sofa is very comfortable.
common|обычный|ˈkɑmən|qualities|Smith is a common name.
company|компания|ˈkʌmpəˌni|work|He works for a big company.
compare|сравнивать|kəmˈpɛr|actions|Compare the two prices.
complete|завершать|kəmˈplit|actions|Complete the form, please.
computer|компьютер|kəmˈpjutɚ|home|My computer is very old.
concert|концерт|ˈkɑnsɚt|general|We went to a rock concert.
condition|состояние|kənˈdɪʃən|general|The car is in good condition.
conversation|разговор|ˌkɑnvɚˈseɪʃən|general|We had a long conversation.
cook|готовить|kʊk|food|I cook dinner for my family.
corner|угол|ˈkɔrnɚ|travel|The shop is on the corner.
correct|правильный|kɚˈɛkt|qualities|Your answer is correct.
cost|стоимость|kɑst|work|What is the cost of the ticket?
country|страна|ˈkʌntri|travel|Which country are you from?
course|курс|kɔrs|work|I'm taking an English course.
cousin|двоюродный родственник|ˈkʌzən|people|My cousin lives in Berlin.
cover|покрывать|ˈkʌvɚ|general|Cover the pot with a lid.
create|создавать|kriˈeɪt|actions|Artists create beautiful things.
cross|пересекать|krɔs|actions|Cross the street carefully.
crowded|переполненный|ˈkraʊdəd|qualities|The bus was crowded.
cry|плакать|kraɪ|actions|Don't cry, it's okay.
culture|культура|ˈkʌltʃɚ|general|I'm interested in Japanese culture.
cup|чашка|kʌp|home|Would you like a cup of tea?
customer|клиент|ˈkʌstəmɚ|people|The customer is always right.
cut|резать|kʌt|actions|Cut the cake in half.
dangerous|опасный|ˈdeɪndʒɚəs|qualities|This road is dangerous.
dark|тёмный|dɑrk|qualities|It gets dark early in winter.
date|дата|deɪt|time|What's the date today?
daughter|дочь|ˈdɔtɚ|people|They have a young daughter.
dead|мёртвый|dɛd|qualities|The flowers are dead.
decide|решать|ˌdɪˈsaɪd|actions|I can't decide what to wear.
deep|глубокий|dip|qualities|The lake is very deep.
delicious|вкусный|dɪˈlɪʃəs|food|This soup is delicious.
describe|описывать|dɪsˈkraɪb|actions|Describe your best friend.
design|дизайн|dɪˈzaɪn|work|I like the design of this phone.
desk|письменный стол|dɛsk|home|She works at her desk.
different|разный|ˈdɪfɚənt|qualities|We have different ideas.
difficult|трудный|ˈdɪfəkəlt|qualities|The test was difficult.
dinner|ужин|ˈdɪnɚ|food|What's for dinner?
direction|направление|dɚˈɛkʃən|travel|Which direction is the station?
dirty|грязный|ˈdɝti|qualities|Your shoes are dirty.
discuss|обсуждать|dɪˈskʌs|actions|Let's discuss the plan.
dish|блюдо|dɪʃ|home|This dish is spicy.
distance|расстояние|ˈdɪstəns|travel|The distance is ten kilometers.
doctor|врач|ˈdɑktɚ|health|I need to see a doctor.
document|документ|ˈdɑkjəmɛnt|work|Please sign this document.
door|дверь|dɔr|home|Open the door, please.
double|двойной|ˈdʌbəl|qualities|I'd like a double coffee.
downstairs|внизу|ˈdaʊnˈstɛrz|home|The kitchen is downstairs.
draw|рисовать|drɔ|actions|She likes to draw animals.
dream|мечта|drim|general|I had a strange dream.
dress|платье|drɛs|home|She wore a red dress.
drink|напиток|drɪŋk|food|Would you like a drink?
drive|водить|draɪv|actions|He drives to work.
driver|водитель|ˈdraɪvɚ|people|The bus driver was friendly.
drop|ронять|drɑp|actions|Don't drop the glass.
dry|сухой|draɪ|nature|The towel is dry.
during|во время|ˈdʊrɪŋ|time|I slept during the flight.
each|каждый|itʃ|general|Each student has a book.
early|рано|ˈɝli|time|I get up early.
earn|зарабатывать|ɝn|work|He earns a good salary.
earth|земля|ɝθ|nature|The Earth moves around the sun.
east|восток|ist|travel|The sun rises in the east.
easy|лёгкий|ˈizi|qualities|The exam was easy.
education|образование|ˌɛdʒəˈkeɪʃən|work|Education is very important.
either|любой из двух|ˈiðɚ|general|You can take either bag.
else|ещё|ɛls|general|Anything else?
email|электронная почта|iˈmeɪl|home|I'll send you an email.
empty|пустой|ˈɛmpti|qualities|The box is empty.
end|конец|ɛnd|general|This is the end of the story.
engine|двигатель|ˈɛndʒən|general|The engine is too loud.
enjoy|наслаждаться|ˌɛnˈdʒɔɪ|actions|I enjoy reading in the evening.
enough|достаточно|ɪˈnʌf|general|I have enough money.
enter|входить|ˈɛntɚ|actions|Please enter the room.
environment|окружающая среда|ɪnˈvaɪrənmənt|nature|We must protect the environment.
especially|особенно|əˈspɛʃli|general|I love fruit, especially apples.
evening|вечер|ˈivnɪŋ|time|Good evening!
event|событие|ɪˈvɛnt|general|It was a great event.
ever|когда-либо|ˈɛvɚ|time|Have you ever been to Spain?
everywhere|везде|ˈɛvriˌwɛr|general|There are flowers everywhere.
example|пример|ɪɡˈzæmpəl|general|Give me an example.
excellent|отличный|ˈɛksələnt|qualities|Your work is excellent.
except|кроме|ɪkˈsɛpt|general|Everyone came except Tom.
excited|взволнованный|ɪkˈsaɪtəd|qualities|I'm excited about the trip.
exercise|упражнение|ˈɛksɚˌsaɪz|health|Daily exercise keeps you healthy.
expensive|дорогой|ɪkˈspɛnsɪv|qualities|That watch is too expensive.
experience|опыт|ɪkˈspɪriəns|general|She has a lot of experience.
explain|объяснять|ɪksˈpleɪn|actions|Can you explain this word?
eye|глаз|aɪ|health|She has blue eyes.
face|лицо|feɪs|health|He washed his face.
fact|факт|fækt|general|That's an interesting fact.
factory|фабрика|ˈfæktɚi|work|My father works in a factory.
fail|терпеть неудачу|feɪl|actions|Don't be afraid to fail.
fair|справедливый|fɛr|qualities|The teacher is strict but fair.
fall|падать|fɔl|actions|Leaves fall in autumn.
family|семья|ˈfæməli|people|I have a big family.
famous|известный|ˈfeɪməs|qualities|She is a famous singer.
far|далеко|fɑr|general|Is it far from here?
farm|ферма|fɑrm|general|They live on a farm.
fast|быстрый|fæst|qualities|He runs very fast.
father|отец|ˈfɑðɚ|people|My father is a teacher.
favorite|любимый|ˈfeɪvɚɪt|qualities|Blue is my favorite color.
feel|чувствовать|fil|actions|I feel tired today.
festival|фестиваль|ˈfɛstəvəl|general|We went to a music festival.
few|несколько|fju|qualities|Only a few people came.
field|поле|fild|nature|Cows are in the field.
fight|драться|faɪt|actions|Don't fight with your brother.
fill|наполнять|fɪl|actions|Fill the glass with water.
film|фильм|fɪlm|general|Let's watch a film tonight.
finally|наконец|ˈfaɪnəli|time|We finally arrived.
find|находить|faɪnd|actions|I can't find my keys.
finger|палец|ˈfɪŋɡɚ|health|She cut her finger.
finish|заканчивать|ˈfɪnɪʃ|actions|I finished my homework.
fire|огонь|ˈfaɪɚ|nature|Don't play with fire.
first|первый|fɝst|general|This is my first visit.
fish|рыба|fɪʃ|food|We had fish for dinner.
floor|пол|flɔr|home|The book is on the floor.
flower|цветок|ˈflaʊɚ|nature|She gave me a flower.
fly|летать|flaɪ|actions|Birds can fly.
follow|следовать|ˈfɑloʊ|actions|Follow me, please.
food|еда|fud|food|I love Italian food.
forest|лес|ˈfɔrəst|nature|We walked through the forest.
forget|забывать|fɚˈɡɛt|actions|I forgot my password.
fork|вилка|fɔrk|home|I need a fork and a knife.
free|свободный|fri|qualities|Are you free tomorrow?
fresh|свежий|frɛʃ|qualities|The bread is fresh.
friend|друг|frɛnd|people|He is my best friend.
friendly|дружелюбный|ˈfrɛndli|qualities|The people here are friendly.
front|передняя часть|frʌnt|general|Sit in the front of the bus.
fruit|фрукт|frut|food|Eat more fruit.
full|полный|fʊl|qualities|The bus is full.
funny|смешной|ˈfʌni|qualities|He told a funny story.
future|будущее|ˈfjutʃɚ|time|What are your plans for the future?
game|игра|ɡeɪm|general|Do you like this game?
garden|сад|ˈɡɑrdən|home|We have a small garden.
gas|газ|ɡæs|nature|Turn off the gas.
general|общий|ˈdʒɛnɚəl|qualities|I have a general idea.
get|получать|ɡɛt|actions|I got a letter today.
gift|подарок|ɡɪft|home|This is a gift for you.
girl|девочка|ɡɝl|people|The girl is reading a book.
give|давать|ɡɪv|actions|Give me your hand.
glass|стакан|ɡlæs|home|Pour some water into the glass.
glove|перчатка|ɡlʌv|home|I lost my left glove.
goal|цель|ɡoʊl|general|My goal is to learn English.
government|правительство|ˈɡʌvɚmənt|work|The government announced new rules.
grade|оценка|ɡreɪd|work|She got a good grade.
great|отличный|ɡreɪt|qualities|That's a great idea.
ground|земля|ɡraʊnd|nature|The ball fell on the ground.
group|группа|ɡrup|general|We work in a group.
grow|расти|ɡroʊ|actions|Plants grow in spring.
guess|угадывать|ɡɛs|actions|Guess how old I am.
guest|гость|ɡɛst|people|We have guests tonight.
guide|гид|ɡaɪd|people|The guide showed us the city.
habit|привычка|ˈhæbət|general|Smoking is a bad habit.
hair|волосы|hɛr|health|She has long hair.
half|половина|hæf|general|Half of the class is absent.
happen|случаться|ˈhæpən|actions|What happened?
happy|счастливый|ˈhæpi|qualities|I'm happy to see you.
hard|трудный|hɑrd|qualities|This exercise is hard.
hat|шляпа|hæt|home|He wears a black hat.
hate|ненавидеть|heɪt|actions|I hate waiting.
head|голова|hɛd|health|My head hurts.
health|здоровье|hɛlθ|health|Health is more important than money.
healthy|здоровый|ˈhɛlθi|health|Eat healthy food.
hear|слышать|hir|actions|I can't hear you.
heart|сердце|hɑrt|health|He has a kind heart.
heavy|тяжёлый|ˈhɛvi|qualities|This bag is very heavy.
help|помогать|hɛlp|actions|Can you help me?
hide|прятать|haɪd|actions|Where did you hide the gift?
high|высокий|haɪ|qualities|The mountain is very high.
hill|холм|hɪl|nature|We walked up the hill.
history|история|ˈhɪstɚi|work|I like to study history.
hold|держать|hoʊld|actions|Hold my hand.
holiday|отпуск|ˈhɑləˌdeɪ|travel|We are on holiday.
home|дом|hoʊm|home|I'm going home.
hope|надеяться|hoʊp|actions|I hope you feel better.
hospital|больница|ˈhɑˌspɪtəl|health|He is in the hospital.
hotel|отель|hoʊˈtɛl|travel|We booked a hotel.
hour|час|ˈaʊɚ|time|The film lasts two hours.
house|дом|haʊs|home|They bought a big house.
however|однако|ˌhaʊˈɛvɚ|general|It's cold; however, we can go.
huge|огромный|hjudʒ|qualities|They have a huge garden.
hungry|голодный|ˈhʌŋɡri|food|I'm very hungry.
hurt|причинять боль|hɝt|health|Don't hurt the cat.
idea|идея|aɪˈdiə|general|That's a good idea.
if|если|ɪf|general|If it rains, we'll stay home.
imagine|представлять|ˌɪˈmædʒən|actions|Imagine a big blue sea.
important|важный|ˌɪmˈpɔrtənt|qualities|This meeting is important.
improve|улучшать|ˌɪmˈpruv|actions|I want to improve my English.
include|включать|ˌɪnˈklud|actions|The price includes breakfast.
information|информация|ˌɪnfɚˈmeɪʃən|general|I need more information.
inside|внутри|ˌɪnˈsaɪd|general|It's warm inside.
instead|вместо|ˌɪnˈstɛd|general|Have tea instead of coffee.
interested|заинтересованный|ˈɪntrəstɪd|qualities|I'm interested in music.
interesting|интересный|ˈɪntrəstɪŋ|qualities|This is an interesting book.
invite|приглашать|ˌɪnˈvaɪt|actions|I invited her to my party.
island|остров|ˈaɪlənd|travel|We live on an island.
job|работа|dʒɑb|work|He found a new job.
join|присоединяться|dʒɔɪn|actions|Join us for dinner.
journey|путешествие|ˈdʒɝni|travel|The journey took three hours.
keep|хранить|kip|actions|Keep the change.
key|ключ|ki|home|I lost my key.
kilometer|километр|kəˈlɑmətɚ|general|The shop is one kilometer away.
kind|добрый|kaɪnd|qualities|She is a kind person.
kitchen|кухня|ˈkɪtʃən|home|Mom is in the kitchen.
knife|нож|naɪf|home|Be careful with the knife.
know|знать|noʊ|actions|I don't know him.
lake|озеро|leɪk|nature|We swam in the lake.
language|язык|ˈlæŋɡwədʒ|work|English is a global language.
large|большой|lɑrdʒ|qualities|They live in a large house.
last|последний|læst|qualities|This is the last bus.
late|поздно|leɪt|time|Don't be late.
later|позже|ˈleɪtɚ|time|See you later!
laugh|смеяться|læf|actions|We laughed a lot.
learn|учить|lɝn|actions|I learn ten new words a day.
leave|уходить|liv|actions|We leave at noon.
left|левый|lɛft|qualities|Turn left at the corner.
leg|нога|lɛɡ|health|He broke his leg.
lesson|урок|ˈlɛsən|work|The lesson starts at nine.
letter|письмо|ˈlɛtɚ|home|I wrote you a letter.
library|библиотека|ˈlaɪbrɛˌri|work|She works in the library.
lie|лежать|laɪ|actions|The book lies on the table.
life|жизнь|laɪf|general|Life is beautiful.
light|свет|laɪt|general|Turn on the light.
like|нравиться|laɪk|actions|I like your shoes.
line|линия|laɪn|general|Stand in a line.
listen|слушать|ˈlɪsən|actions|Listen to the teacher.
little|маленький|ˈlɪtəl|qualities|She has a little dog.
local|местный|ˈloʊkəl|qualities|We eat local food.
lose|терять|luz|actions|Don't lose your keys.
loud|громкий|laʊd|qualities|The music is too loud.
love|любить|lʌv|actions|I love my family.
lucky|удачливый|ˈlʌki|qualities|You are lucky!
lunch|обед|lʌntʃ|food|We have lunch at noon.
machine|машина|məˈʃin|home|The washing machine is broken.
magazine|журнал|ˈmæɡəˌzin|home|She reads a fashion magazine.
main|главный|meɪn|qualities|The main street is closed.
make|делать|meɪk|actions|I make coffee every morning.
manager|менеджер|ˈmænədʒɚ|people|The manager is in a meeting.
map|карта|mæp|home|Look at the map.
market|рынок|ˈmɑrkət|travel|We buy vegetables at the market.
married|женатый|ˈmɛrid|qualities|They are married.
match|матч|mætʃ|general|We watched the football match.
meal|приём пищи|mil|food|Dinner is my favorite meal.
mean|означать|min|actions|What does this word mean?
medicine|лекарство|ˈmɛdəsən|health|Take this medicine twice a day.
meet|встречать|mit|actions|Nice to meet you.
meeting|встреча|ˈmitɪŋ|work|The meeting is at ten.
member|участник|ˈmɛmbɚ|people|He is a member of the club.
message|сообщение|ˈmɛsədʒ|general|I got your message.
middle|середина|ˈmɪdəl|general|She sat in the middle.
might|возможно|maɪt|general|It might rain tomorrow.
minute|минута|ˈmɪnət|time|Wait a minute.
miss|скучать|mɪs|actions|I miss my family.
mistake|ошибка|mɪˈsteɪk|general|I made a mistake.
modern|современный|ˈmɑdɚn|qualities|This is a modern building.
moment|момент|ˈmoʊmənt|time|Just a moment, please.
money|деньги|ˈmʌni|work|I have no money.
month|месяц|mʌnθ|time|February is a short month.
moon|луна|mun|nature|The moon is bright tonight.
more|больше|mɔr|general|I need more time.
morning|утро|ˈmɔrnɪŋ|time|Good morning!
most|большинство|moʊst|general|Most people like music.
mother|мать|ˈmʌðɚ|people|My mother is a nurse.
mountain|гора|ˈmaʊntən|nature|We climbed a high mountain.
move|двигаться|muv|actions|Please move your car.
movie|фильм|ˈmuvi|general|Let's watch a movie.
much|много|mʌtʃ|general|How much is it?
museum|музей|mjuˈziəm|travel|We visited the museum.
music|музыка|mˈjuzɪk|general|I listen to music every day.
must|должен|mʌst|general|You must wear a seat belt.
name|имя|neɪm|general|What's your name?
nature|природа|ˈneɪtʃɚ|nature|I love walking in nature.
near|рядом|nɪr|general|The hotel is near the beach.
necessary|необходимый|ˈnɛsəˌsɛri|qualities|Water is necessary for life.
need|нуждаться|nid|actions|I need your help.
neighbor|сосед|ˈneɪbɚ|people|My neighbor has a dog.
never|никогда|ˈnɛvɚ|time|I never drink coffee at night.
news|новости|nuz|general|Did you hear the news?
newspaper|газета|ˈnuzˌpeɪpɚ|home|He reads the newspaper.
next|следующий|nɛkst|general|See you next week.
nice|приятный|naɪs|qualities|What a nice day!
night|ночь|naɪt|time|Good night!
noise|шум|nɔɪz|general|I heard a strange noise.
north|север|nɔrθ|travel|Canada is north of the USA.
nose|нос|noʊz|health|He has a long nose.
note|заметка|noʊt|work|She left me a note.
nothing|ничего|ˈnʌθɪŋ|general|There is nothing in the box.
notice|замечать|ˈnoʊtəs|actions|I didn't notice the sign.
number|число|ˈnʌmbɚ|general|What's your phone number?
office|офис|ˈɔfɪs|work|She works in an office.
often|часто|ˈɔfən|time|We often go to the cinema.
once|однажды|wʌns|time|I visited Rome once.
only|только|ˈoʊnli|general|I have only one brother.
open|открывать|ˈoʊpən|actions|Open the window, please.
opinion|мнение|əˈpɪnjən|general|What's your opinion?
opportunity|возможность|ˌɑpɚˈtunəti|general|This is a great opportunity.
opposite|противоположный|ˈɑpəzət|general|The bank is opposite the school.
order|заказывать|ˈɔrdɚ|actions|I'd like to order a pizza.
outside|снаружи|ˈaʊtˈsaɪd|general|The children are playing outside.
own|собственный|oʊn|qualities|She has her own room.
page|страница|peɪdʒ|work|Open the book at page ten.
paint|рисовать красками|peɪnt|actions|I like to paint flowers.
pair|пара|pɛr|general|I bought a new pair of shoes.
paper|бумага|ˈpeɪpɚ|home|I need a sheet of paper.
parent|родитель|ˈpɛrənt|people|My parents live in the country.
park|парк|pɑrk|travel|We walk in the park.
party|вечеринка|ˈpɑrti|general|She invited us to a party.
pass|проходить|pæs|actions|We pass the school on our way home.
passenger|пассажир|ˈpæsəndʒɚ|people|The train was full of passengers.
pay|платить|peɪ|actions|I'll pay by card.
people|люди|ˈpipəl|people|Many people like pizza.
perhaps|возможно|pɚˈhæps|general|Perhaps he is at home.
person|человек|ˈpɝsən|people|She is a very kind person.
phone|телефон|foʊn|home|My phone is on the table.
photo|фотография|ˈfoʊˌtoʊ|home|Can I take a photo?
pick|выбирать|pɪk|actions|Pick a card.
picture|картина|ˈpɪktʃɚ|home|There is a picture on the wall.
piece|кусок|pis|general|Would you like a piece of cake?
place|место|pleɪs|general|This is a nice place.
plan|план|plæn|general|What's your plan for tomorrow?
plane|самолёт|pleɪn|travel|The plane lands at six.
plant|растение|plænt|nature|Water the plants every day.
plate|тарелка|pleɪt|home|Put the food on the plate.
play|играть|pleɪ|actions|The children play in the yard.
police|полиция|pəˈlis|people|Call the police!
popular|популярный|ˈpɑpjəlɚ|qualities|This song is very popular.
possible|возможный|ˈpɑsəbəl|qualities|Is it possible to pay by card?
post|почта|poʊst|general|I'll send it by post.
practice|практика|ˈpræktəs|actions|Practice makes perfect.
prefer|предпочитать|prəˈfɝ|actions|I prefer tea to coffee.
prepare|готовить|priˈpɛr|actions|I'm preparing dinner.
present|подарок|ˈprɛzənt|home|She gave me a nice present.
pretty|симпатичный|ˈprɪti|qualities|What a pretty dress!
price|цена|praɪs|work|The price is too high.
probably|вероятно|ˈprɑbəˌbli|general|He will probably be late.
problem|проблема|ˈprɑbləm|general|We have a problem.
product|товар|ˈprɑdəkt|work|The shop sells local products.
program|программа|ˈproʊˌɡræm|work|I like this TV program.
project|проект|ˈprɑdʒɛkt|work|We are working on a new project.
promise|обещать|ˈprɑməs|actions|I promise to call you.
protect|защищать|prəˈtɛkt|actions|Wear a hat to protect your head.
proud|гордый|praʊd|qualities|I'm proud of you.
public|общественный|ˈpʌblɪk|qualities|There is a public library here.
pull|тянуть|pʊl|actions|Pull the door.
push|толкать|pʊʃ|actions|Push the button.
question|вопрос|ˈkwɛstʃən|work|Can I ask a question?
quick|быстрый|kwɪk|qualities|Take a quick look.
quiet|тихий|ˈkwaɪət|qualities|The street is quiet at night.
quite|довольно|kwaɪt|general|It's quite cold today.
radio|радио|ˈreɪdiˌoʊ|home|He listens to the radio.
rain|дождь|reɪn|nature|I love the sound of rain.
ready|готовый|ˈrɛdi|qualities|Dinner is ready.
real|настоящий|ril|qualities|Is this a real diamond?
reason|причина|ˈrizən|general|What is the reason?
receive|получать|rəˈsiv|actions|I received your letter.
remember|помнить|rɪˈmɛmbɚ|actions|I remember this song.
rent|арендовать|rɛnt|actions|We rent a small flat.
repeat|повторять|rɪˈpit|actions|Please repeat the question.
reply|отвечать|rɪˈplaɪ|actions|She didn't reply to my email.
restaurant|ресторан|ˈrɛstɚˌɑnt|food|Let's eat at a restaurant.
result|результат|rɪˈzʌlt|general|The result was surprising.
return|возвращаться|rɪˈtɝn|actions|He will return next week.
rice|рис|raɪs|food|I eat rice every day.
rich|богатый|rɪtʃ|qualities|He is a rich man.
ride|ехать|raɪd|actions|I ride my bike to school.
right|правый|raɪt|qualities|Turn right at the lights.
river|река|ˈrɪvɚ|nature|The river is wide.
road|дорога|roʊd|travel|This road is busy.
room|комната|rum|home|My room is small.
round|круглый|raʊnd|qualities|The table is round.
safe|безопасный|seɪf|qualities|Is it safe to swim here?
same|одинаковый|seɪm|qualities|We have the same phone.
save|сохранять|seɪv|actions|Save your work.
say|говорить|seɪ|actions|What did you say?
school|школа|skul|work|The children go to school.
science|наука|ˈsaɪəns|work|I like science.
sea|море|si|nature|We swim in the sea.
season|сезон|ˈsizən|time|Summer is my favorite season.
seat|место|sit|general|Is this seat free?
second|второй|ˈsɛkənd|qualities|This is my second try.
sell|продавать|sɛl|actions|They sell fresh bread.
send|отправлять|sɛnd|actions|Send me a message.
sentence|предложение|ˈsɛntəns|work|Write a short sentence.
serious|серьёзный|ˈsɪriəs|qualities|This is a serious problem.
service|услуга|ˈsɝvəs|work|The service was great.
share|делиться|ʃɛr|actions|Let's share the pizza.
shop|магазин|ʃɑp|travel|The shop opens at nine.
short|короткий|ʃɔrt|qualities|The film is very short.
should|следует|ʃʊd|general|You should rest.
show|показывать|ʃoʊ|actions|Show me your photos.
sick|больной|sɪk|health|I feel sick.
side|сторона|saɪd|general|He sat by my side.
simple|простой|ˈsɪmpəl|qualities|The rules are simple.
since|с тех пор|sɪns|time|I've lived here since 2020.
sing|петь|sɪŋ|actions|She sings in a choir.
sister|сестра|ˈsɪstɚ|people|My sister is older than me.
sit|сидеть|sɪt|actions|Sit down, please.
situation|ситуация|ˌsɪtʃuˈeɪʃən|general|The situation is difficult.
sleep|спать|slip|health|I sleep eight hours a night.
slow|медленный|sloʊ|qualities|The train is slow.
small|маленький|smɔl|qualities|It's a small town.
smile|улыбаться|smaɪl|actions|Smile, please!
snow|снег|snoʊ|nature|It snows a lot in winter.
so|поэтому|soʊ|general|It was raining, so we stayed home.
someone|кто-то|ˈsʌmˌwʌn|general|Someone is at the door.
something|что-то|ˈsʌmθɪŋ|general|I want to eat something.
sometimes|иногда|səmˈtaɪmz|time|Sometimes I walk to work.
soon|скоро|sun|time|See you soon!
sorry|сожалеющий|ˈsɑri|qualities|I'm sorry I'm late.
sound|звук|saʊnd|general|I heard a strange sound.
south|юг|saʊθ|travel|Spain is in the south of Europe.
space|пространство|speɪs|general|There is no space in the car.
speak|говорить|spik|actions|Do you speak English?
special|особенный|ˈspɛʃəl|qualities|Today is a special day.
spend|тратить|spɛnd|actions|I spend too much money.
sport|спорт|spɔrt|general|My favorite sport is tennis.
spring|весна|sprɪŋ|time|Flowers bloom in spring.
stand|стоять|stænd|actions|Please stand up.
start|начинать|stɑrt|actions|The lesson starts at nine.
station|станция|ˈsteɪʃən|travel|The station is near.
stay|оставаться|steɪ|actions|Stay with me.
still|всё ещё|stɪl|time|He is still sleeping.
stop|останавливать|stɑp|actions|Stop the car!
story|история|ˈstɔri|general|Tell me a story.
street|улица|strit|travel|I live on this street.
strong|сильный|strɔŋ|qualities|He is very strong.
student|студент|ˈstudənt|people|She is a university student.
study|учиться|ˈstʌdi|actions|I study English every day.
successful|успешный|səkˈsɛsfəl|qualities|He is a successful businessman.
suddenly|внезапно|ˈsʌdənli|time|Suddenly it started to rain.
summer|лето|ˈsʌmɚ|time|We swim in summer.
sun|солнце|sʌn|nature|The sun is shining.
sure|уверенный|ʃʊr|qualities|Are you sure?
table|стол|ˈteɪbəl|home|Put the book on the table.
take|брать|teɪk|actions|Take your umbrella.
talk|разговаривать|tɔk|actions|Let's talk after lunch.
tall|высокий|tɔl|qualities|He is tall.
teach|обучать|titʃ|actions|She teaches English.
teacher|учитель|ˈtitʃɚ|people|My teacher is kind.
team|команда|tim|people|Our team won.
tell|рассказывать|tɛl|actions|Tell me the truth.
temperature|температура|ˈtɛmprətʃɚ|health|The temperature is 20 degrees.
than|чем|ðæn|general|She is taller than me.
thank|благодарить|θæŋk|actions|I want to thank you.
their|их|ðɛr|general|This is their house.
then|затем|ðɛn|general|First wash, then dry.
there|там|ðɛr|general|Put it over there.
thing|вещь|θɪŋ|general|What is this thing?
think|думать|θɪŋk|actions|I think so.
through|через|θru|general|We drove through the forest.
ticket|билет|ˈtɪkət|travel|I bought two tickets.
tidy|аккуратный|ˈtaɪdi|qualities|Keep your room tidy.
time|время|taɪm|time|What time is it?
tired|уставший|ˈtaɪɚd|health|I'm tired.
today|сегодня|təˈdeɪ|time|Today is Monday.
together|вместе|təˈɡɛðɚ|general|We work together.
tomorrow|завтра|təˈmɑˌroʊ|time|See you tomorrow.
tonight|сегодня вечером|təˈnaɪt|time|What are you doing tonight?
town|городок|taʊn|travel|We live in a small town.
traffic|движение|ˈtræfɪk|travel|The traffic is heavy.
train|поезд|treɪn|travel|The train leaves at noon.
travel|путешествовать|ˈtrævəl|travel|I love to travel.
trip|поездка|trɪp|travel|We went on a trip.
true|верный|tru|qualities|Is that true?
try|пытаться|traɪ|actions|Try this cake.
turn|поворачивать|tɝn|actions|Turn left here.
understand|понимать|ˌʌndɚˈstænd|actions|I don't understand.
university|университет|ˌjunəˈvɝsəti|work|He studies at university.
until|до тех пор|ənˈtɪl|time|Wait until I come back.
upstairs|наверху|əpˈstɛrz|home|The bedroom is upstairs.
useful|полезный|ˈjusfəl|qualities|This app is very useful.
usually|обычно|ˈjuʒəwəli|time|I usually get up at seven.
vacation|отпуск|veɪˈkeɪʃən|travel|We're on vacation.
vegetable|овощ|ˈvɛdʒtəbəl|food|Eat more vegetables.
very|очень|ˈvɛri|general|It's very cold.
village|деревня|ˈvɪlədʒ|travel|He lives in a small village.
visit|посещать|ˈvɪzɪt|travel|I visit my grandmother on Sundays.
wait|ждать|weɪt|actions|Wait for me.
wake|просыпаться|weɪk|actions|I wake up at seven.
walk|ходить|wɔk|actions|We walk to school.
wall|стена|wɔl|home|There's a picture on the wall.
want|хотеть|wɑnt|actions|I want some water.
warm|тёплый|wɔrm|qualities|It's warm today.
wash|мыть|wɑʃ|actions|Wash your hands.
watch|смотреть|wɑtʃ|actions|I watch TV in the evening.
water|вода|ˈwɔtɚ|food|Drink more water.
way|путь|weɪ|travel|Which way is the station?
weather|погода|ˈwɛðɚ|nature|The weather is nice today.
week|неделя|wik|time|I work five days a week.
welcome|добро пожаловать|ˈwɛlkəm|general|Welcome to our home!
well|хорошо|wɛl|general|She speaks English well.
west|запад|wɛst|travel|The sun sets in the west.
wet|мокрый|wɛt|nature|My shoes are wet.
while|пока|waɪl|time|I read while I wait.
white|белый|waɪt|qualities|She wore a white dress.
whole|целый|hoʊl|qualities|I ate the whole pizza.
wife|жена|waɪf|people|His wife is a doctor.
win|побеждать|wɪn|actions|We want to win.
window|окно|ˈwɪndoʊ|home|Open the window, please.
winter|зима|ˈwɪntɚ|time|It's cold in winter.
wish|желать|wɪʃ|actions|I wish you luck.
without|без|wɪˈθaʊt|general|I can't live without music.
woman|женщина|ˈwʊmən|people|That woman is my teacher.
wonderful|замечательный|ˈwʌndɚfəl|qualities|What a wonderful day!
word|слово|wɝd|work|I don't know this word.
work|работать|wɝk|actions|I work in a bank.
world|мир|wɝld|nature|The world is big.
worry|беспокоиться|ˈwɝi|actions|Don't worry.
write|писать|raɪt|actions|Write your name here.
wrong|неправильный|rɔŋ|qualities|This is the wrong way.
year|год|jɪr|time|A year has twelve months.
young|молодой|jʌŋ|qualities|He is too young.
"""
}
