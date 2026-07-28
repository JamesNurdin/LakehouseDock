WITH filtered_sales AS (
    SELECT
        hd.hd_buy_potential,
        p.p_promo_name,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_ticket_number
    FROM tpcds.store_sales ss
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE hd.hd_buy_potential = '5001-10000'
      AND hd.hd_dep_count >= 3
      AND p.p_channel_details LIKE '%old%'
)
SELECT
    hd_buy_potential,
    p_promo_name,
    COUNT(DISTINCT ss_ticket_number) AS num_tickets,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_quantity) AS avg_quantity,
    MAX(ss_ext_sales_price) AS max_ext_sales_price
FROM filtered_sales
GROUP BY
    hd_buy_potential,
    p_promo_name
ORDER BY total_net_paid DESC
LIMIT 10
