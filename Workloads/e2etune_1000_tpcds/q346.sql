WITH gender_potential_sales AS (
    SELECT
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_net_paid) AS total_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_gender IN ('M', 'F')
      AND hd.hd_buy_potential IN ('High', 'Medium')
      AND ss.ss_quantity > 0
      AND ss.ss_sold_date_sk BETWEEN 2458000 AND 2458365
    GROUP BY cd.cd_gender, hd.hd_buy_potential
)
SELECT
    cd_gender,
    hd_buy_potential,
    total_profit,
    total_paid,
    avg_discount,
    distinct_items,
    transaction_cnt,
    profit_rank
FROM (
    SELECT
        cd_gender,
        hd_buy_potential,
        total_profit,
        total_paid,
        avg_discount,
        distinct_items,
        transaction_cnt,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS profit_rank
    FROM gender_potential_sales
) ranked
WHERE profit_rank <= 3
ORDER BY cd_gender, profit_rank
