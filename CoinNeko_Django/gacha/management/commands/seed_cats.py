# backend/gacha/management/commands/seed_cats.py
# 執行: python manage.py seed_cats
from django.core.management.base import BaseCommand
from gacha.models import CatSpecies

CATS = [
    # === 初始 12 隻 ===
    {'name': '小廚師', 'job_title': '廚師貓', 'rarity': 'common', 'emoji': '👨‍🍳', 'description': '看到菜價上漲會眉頭一皺，對食材CP值有莫名的偏執。'},
    {'name': '米津律師', 'job_title': '律師貓', 'rarity': 'rare', 'emoji': '⚖️', 'description': '結帳時心算絕對比收銀機還快，連一塊錢都不放過。'},
    {'name': '科技貓', 'job_title': '程式貓', 'rarity': 'rare', 'emoji': '💻', 'description': '靠著肝指數換薪水，最大的願望是程式一次跑過不要報錯。'},
    {'name': '白袍喵', 'job_title': '護士貓', 'rarity': 'common', 'emoji': '🏥', 'description': '職業病是看到帳本赤字就像看到血壓飆高一樣緊張。'},
    {'name': '書生貓', 'job_title': '老師貓', 'rarity': 'common', 'emoji': '📚', 'description': '堅信「書中自有黃金屋」，但買書的錢永遠比賺的還多。'},
    {'name': '江戶川柯南', 'job_title': '偵探貓', 'rarity': 'epic', 'emoji': '🔍', 'description': '你以為不見的五十塊，其實都難逃牠的法眼。'},
    {'name': '阿姆斯壯', 'job_title': '太空人貓', 'rarity': 'epic', 'emoji': '🚀', 'description': '腦波極弱，只要看到特價，錢包經常呈現無重力狀態。'},
    {'name': '藝術喵', 'job_title': '畫家貓', 'rarity': 'rare', 'emoji': '🎨', 'description': '買顏料花錢如流水，只能把月底吃土的日常畫成悲傷油畫。'},
    {'name': '火車呼嚕嚕', 'job_title': '火車貓', 'rarity': 'common', 'emoji': '🚂', 'description': '每天精算1200通勤月票到底要搭幾次才回本的精明貓貓。'},
    {'name': '魔法貓', 'job_title': '魔法師貓', 'rarity': 'legendary', 'emoji': '🪄', 'description': '會用神秘咒語讓戶頭數字變多（其實只是定存利息發了）。'},
    {'name': '船長喵', 'job_title': '船長貓', 'rarity': 'epic', 'emoji': '⚓', 'description': '股市裡的超級航海王，看到綠油油的跌停板也面不改色。'},
    {'name': '冰冰的貓', 'job_title': '雪花貓', 'rarity': 'legendary', 'emoji': '❄️', 'description': '夏天的時候很有幫助，但冬天的時候抱牠會冷。'},

    # === 普通級 (Common) ===
    {'name': '拉花大師', 'job_title': '咖啡師貓', 'rarity': 'common', 'emoji': '☕', 'description': '寧願午餐少吃一點，也絕對要喝一杯星巴克續命。'},
    {'name': '麵包超人', 'job_title': '烘焙貓', 'rarity': 'common', 'emoji': '🥐', 'description': '看到剛出爐的麵包就腦波弱，恩格爾係數嚴重超標。'},
    {'name': '菜市場阿姨', 'job_title': '攤販貓', 'rarity': 'common', 'emoji': '🥬', 'description': '「老闆算便宜一點啦！」這句話已經刻在牠的DNA裡。'},
    {'name': '街頭藝人', 'job_title': '駐唱貓', 'rarity': 'common', 'emoji': '🎸', 'description': '街頭賣藝賺來的打賞，剛好夠買晚上的超商打折便當。'},
    {'name': '使命必達', 'job_title': '外送貓', 'rarity': 'common', 'emoji': '🛵', 'description': '只要有跑單加給，半夜三點送飲料上陽明山也使命必達。'},
    {'name': '壯壯壯貓', 'job_title': '教練貓', 'rarity': 'common', 'emoji': '🏋️‍♂️', 'description': '覺得與其花錢看醫生，不如把錢全拿去買高蛋白粉。'},
    {'name': '超柔軟貓', 'job_title': '瑜珈貓', 'rarity': 'common', 'emoji': '🧘', 'description': '只要靜下心來打坐，就感覺不到月底肚子餓了呢。'},
    {'name': '熬夜追劇', 'job_title': '沙發貓', 'rarity': 'common', 'emoji': '🍿', 'description': '為了看獨家韓劇，默默綁定了五個串流平台當盤子。'},
    {'name': '超大鏡頭', 'job_title': '攝影貓', 'rarity': 'common', 'emoji': '📷', 'description': '攝影窮三代，為了買新鏡頭已經吃了兩個月的泡麵。'},
    {'name': '種花貓貓', 'job_title': '園丁貓', 'rarity': 'common', 'emoji': '🌻', 'description': '買觀葉植物花了一大筆錢，結果最後還是養死。'},
    {'name': '白衣天使', 'job_title': '護理貓', 'rarity': 'common', 'emoji': '💉', 'description': '日夜顛倒排班換來的血汗錢，常常不小心就報復性消費。'},
    {'name': '熱血教師', 'job_title': '教育貓', 'rarity': 'common', 'emoji': '🏫', 'description': '苦口婆心勸學生存錢，自己卻愛瘋狂抽各種盲盒玩具。'},
    {'name': '上下車都要刷卡', 'job_title': '公車貓', 'rarity': 'common', 'emoji': '🚌', 'description': '為了省十塊錢的捷運轉乘費，寧願多走十五分鐘的路。'},
    {'name': '家事達人', 'job_title': '管家貓', 'rarity': 'common', 'emoji': '🧹', 'description': '看到大賣場特價的衛生紙，不囤個五箱就會渾身不對勁。'},
    {'name': '很會管理書', 'job_title': '圖書管理員貓', 'rarity': 'common', 'emoji': '📖', 'description': '善用圖書館資源的終極白嫖客，堅持絕對不買實體書。'},
    {'name': '很會收銀', 'job_title': '超商貓', 'rarity': 'common', 'emoji': '🏪', 'description': '每天看盡奧客的臉色，最大的願望是準時下班吃宵夜。'},
    {'name': '修修補補', 'job_title': '裁縫貓', 'rarity': 'common', 'emoji': '🧵', 'description': '東西壞了第一反應是「還能修」，絕對不輕易被勸敗換新。'},
    {'name': '拯救動物', 'job_title': '獸醫貓', 'rarity': 'common', 'emoji': '🐶', 'description': '自己吃得很隨便，但動物的罐頭絕對要買最頂的。'},
    {'name': '貓貓先生有快遞', 'job_title': '物流貓', 'rarity': 'common', 'emoji': '📦', 'description': '看著大家瘋狂網購，常常懷疑大家是不是背著牠偷偷發財。'},
    {'name': '洗車大師', 'job_title': '洗車貓', 'rarity': 'common', 'emoji': '🧽', 'description': '賺的都是勞力辛苦錢，每一分錢絕對都花在刀口上。'},

    # === 稀有級 (Rare) ===
    {'name': '豚骨拉麵', 'job_title': '拉麵師傅貓', 'rarity': 'rare', 'emoji': '🍜', 'description': '吃拉麵一定要選麵硬味濃，為了排人氣名店可以站兩個小時。'},
    {'name': '無人機貓', 'job_title': '飛手貓', 'rarity': 'rare', 'emoji': '🚁', 'description': '正在苦讀準備考證照，等當完兵就要靠這個接案發大財。'},
    {'name': '爆肝打字機', 'job_title': '工程師貓', 'rarity': 'rare', 'emoji': '💻', 'description': '靠著吞Ｂ群和咖啡撐過無數個死線，最恨聽到「需求變更」。'},
    {'name': '靈感泉源', 'job_title': '貼圖畫家貓', 'rarity': 'rare', 'emoji': '🎨', 'description': '曾經熬夜爆肝畫了一套 40 張的貓咪貼圖，結果現在只剩自己買來用。'},
    {'name': '正義鐵槌', 'job_title': '法官貓', 'rarity': 'rare', 'emoji': '⚖️', 'description': '「你真的需要這個酷東西嗎？」每次你想亂花錢時牠都會在耳邊低語。'},
    {'name': '不會開飛機', 'job_title': '機長貓', 'rarity': 'rare', 'emoji': '✈️', 'description': '出國玩絕對要搶到超便宜的紅眼廉航機票，算盤打得超精。'},
    {'name': '深海尋寶', 'job_title': '潛水貓', 'rarity': 'rare', 'emoji': '🤿', 'description': '總能在特賣會花車的最深處，精準挖到便宜又好看的衣服。'},
    {'name': '好多猩猩', 'job_title': '天文貓', 'rarity': 'rare', 'emoji': '🔭', 'description': '經常因為看星星看到忘我，不小心錯過末班車只好花大錢搭計程車。'},
    {'name': '建築師阿貓', 'job_title': '建築貓', 'rarity': 'rare', 'emoji': '🏗️', 'description': '重度強迫症，記帳的每一筆數字連尾數都必須對齊得整整齊齊。'},
    {'name': '變變變變', 'job_title': '魔術貓', 'rarity': 'rare', 'emoji': '🎩', 'description': '聲稱能把錢變不見，結果只是藏在洗衣機裡的外套口袋裡。'},
    {'name': '只會指揮', 'job_title': '指揮家貓', 'rarity': 'rare', 'emoji': '🎼', 'description': '信用卡的回饋節奏與趴數抓得極度精準，傳說中的「卡神」。'},
    {'name': '很會甩尾', 'job_title': '賽車貓', 'rarity': 'rare', 'emoji': '🏎️', 'description': '買股票喜歡當沖，心臟很大顆，但偶爾也是會翻車跌進水溝。'},
    {'name': '雪中送雪', 'job_title': '滑雪貓', 'rarity': 'rare', 'emoji': '⛷️', 'description': '當你月底戶頭剩下兩位數時，牠會默默借你五百塊的大好人。'},
    {'name': '荒野求生', 'job_title': '露營貓', 'rarity': 'rare', 'emoji': '⛺', 'description': '崇尚極簡生活，最高紀錄是一個禮拜靠白吐司只花了一千塊。'},
    {'name': '酒流十家', 'job_title': '調酒貓', 'rarity': 'rare', 'emoji': '🍸', 'description': '下班後最喜歡去酒吧喝一杯，但結帳時看到帳單會瞬間清醒。'},

    # === 史詩級 (Epic) ===
    {'name': '追星狂粉', 'job_title': '追星貓', 'rarity': 'epic', 'emoji': '✨', 'description': '很喜歡 winter ，為了買小卡和演唱會門票連泡麵都願意吃。'},
    {'name': '暗夜潛行', 'job_title': '黑客貓', 'rarity': 'epic', 'emoji': '🕶️', 'description': '資管系的隱藏高手，資料結構跟演算法作業總是能用最詭異的方式解開。'},
    {'name': '流量密碼', 'job_title': '百萬網紅貓', 'rarity': 'epic', 'emoji': '📱', 'description': '隨便發個廢文都有幾千個讚，靠業配賺得比你想像的還要多很多。'},
    {'name': '預見未來', 'job_title': '占卜貓', 'rarity': 'epic', 'emoji': '🔮', 'description': '其實根本不會算命，只是用手機大數據偷聽猜出你下個月會買什麼。'},
    {'name': '古墓奇兵', 'job_title': '考古貓', 'rarity': 'epic', 'emoji': '🦴', 'description': '真正的特異功能是每次換季整理衣服，都能在舊外套口袋摸出兩百塊。'},
    {'name': '非常bow欠', 'job_title': '弓箭手貓', 'rarity': 'epic', 'emoji': '🏹', 'description': '網購搶單手速極快，雙11的限量特價品絕對逃不出牠的手掌心。'},
    {'name': '忍者寧賈', 'job_title': '忍者貓', 'rarity': 'epic', 'emoji': '🥷', 'description': '喜歡把私房錢藏在極度隱密的地方，結果時間久了連自己都忘記放哪。'},
    {'name': '錢包太空', 'job_title': '太空貓', 'rarity': 'epic', 'emoji': '🚀', 'description': '買了超多虛擬貨幣夢想一飛衝天上太空，目前還在地球表面吃土。'},
    {'name': '通通很靈', 'job_title': '通靈貓', 'rarity': 'epic', 'emoji': '👻', 'description': '專門負責安撫那些因為你衝動購物，而白白慘死花掉的鈔票怨靈。'},
    {'name': '百戰百勝', 'job_title': '電競貓', 'rarity': 'epic', 'emoji': '🎮', 'description': '雖然常常打電動打到忘記吃飯，但比賽贏下來的獎金非常可觀。'},

    # === 傳說級 (Legendary) ===
    {'name': '貓咪國國王', 'job_title': '國王貓', 'rarity': 'legendary', 'emoji': '👑', 'description': '財富自由的頂點，據說出門連發票都不拿，因為懶得對獎。'},
    {'name': '蛤利波特', 'job_title': '魔法師貓', 'rarity': 'legendary', 'emoji': '🪄', 'description': '運氣好到隨便買張刮刮樂都會中獎，擁有純正的歐洲人血統。'},
    {'name': '發給我紅包', 'job_title': '財神貓', 'rarity': 'legendary', 'emoji': '🧧', 'description': '傳說中，每個月初能把你記帳本的錯誤爛帳一筆勾銷的神秘力量。'},
    {'name': 'Too Long', 'job_title': '屠龍貓', 'rarity': 'legendary', 'emoji': '🐉', 'description': '能夠無情輾壓所有信用卡卡債，連走路都有風的傳說級大佬。'},
    {'name': '一籠馬斯克', 'job_title': '鑽石貓', 'rarity': 'legendary', 'emoji': '💎', 'description': '不要問牠的戶頭到底有多少錢，因為那數字連牠自己也數不完。'}
]

CATEGORIES = [
    {'name': '薪資', 'icon': '💼', 'type': 'income'},
    {'name': '獎金', 'icon': '🎁', 'type': 'income'},
    {'name': '投資', 'icon': '📈', 'type': 'income'},
    {'name': '副業', 'icon': '💡', 'type': 'income'},
    {'name': '其他收入', 'icon': '💰', 'type': 'income'},
    {'name': '餐飲', 'icon': '🍱', 'type': 'expense'},
    {'name': '交通', 'icon': '🚌', 'type': 'expense'},
    {'name': '購物', 'icon': '🛍️', 'type': 'expense'},
    {'name': '娛樂', 'icon': '🎮', 'type': 'expense'},
    {'name': '醫療', 'icon': '💊', 'type': 'expense'},
    {'name': '房租', 'icon': '🏠', 'type': 'expense'},
    {'name': '水電', 'icon': '💡', 'type': 'expense'},
    {'name': '教育', 'icon': '📖', 'type': 'expense'},
    {'name': '旅遊', 'icon': '✈️', 'type': 'expense'},
    {'name': '其他支出', 'icon': '📌', 'type': 'expense'},
]


class Command(BaseCommand):
    help = '初始化貓咪物種與類別資料'

    def handle(self, *args, **options):
        from ledger.models import Category

        # Seed categories
        cat_created = 0
        for c in CATEGORIES:
            _, created = Category.objects.get_or_create(
                name=c['name'], type=c['type'],
                defaults={'icon': c['icon']}
            )
            if created:
                cat_created += 1
        self.stdout.write(f'✅ 建立 {cat_created} 個類別')

        # Seed cat species
        species_created = 0
        for cat in CATS:
            _, created = CatSpecies.objects.get_or_create(
                name=cat['name'],
                defaults={
                    'job_title': cat['job_title'],
                    'rarity': cat['rarity'],
                    'emoji': cat['emoji'],
                    'description': cat['description'],
                }
            )
            if created:
                species_created += 1
        self.stdout.write(f'✅ 建立 {species_created} 隻貓咪')
        self.stdout.write(self.style.SUCCESS('🐱 資料初始化完成！'))