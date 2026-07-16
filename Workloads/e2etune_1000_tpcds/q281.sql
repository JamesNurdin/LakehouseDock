WITH sales_agg AS (
    SELECT
        s.s_store_name AS s_store_name,
        p.p_promo_name AS p_promo_name,
        cd.cd_gender AS cd_gender,
        hd.hd_buy_potential AS hd_buy_potential,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
      AND s.s_closed_date_sk IS NULL
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY s.s_store_name, p.p_promo_name, cd.cd_gender, hd.hd_buy_potential
    HAVING SUM(ss.ss_quantity) > 1000
)
SELECT
    s_store_name,
    p_promo_name,
    cd_gender,
    hd_buy_potential,
    total_net_profit,
    avg_discount_amount,
    total_quantity,
    distinct_tickets,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_net_profit DESC) AS promo_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 20
