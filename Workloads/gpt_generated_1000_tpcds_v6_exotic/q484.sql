WITH sales_cte AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_ext_list_price,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_item_sk
    FROM store_sales ss
    WHERE ss.ss_ext_list_price > 3000.00
      AND ss.ss_quantity >= 2
      AND ss.ss_net_paid IS NOT NULL
)
SELECT
    s.s_store_id,
    s.s_state,
    td.t_hour,
    hd.hd_buy_potential,
    COUNT(DISTINCT sf.ss_ticket_number)               AS num_tickets,
    SUM(sf.ss_net_paid)                               AS total_net_paid,
    AVG(CASE WHEN sr.sr_refunded_cash IS NOT NULL THEN sr.sr_refunded_cash END) AS avg_refunded_cash,
    MIN(sf.ss_ext_list_price)                         AS min_ext_list_price,
    MAX(sf.ss_ext_list_price)                         AS max_ext_list_price,
    CASE
        WHEN hd.hd_dep_count >= 4 THEN 'LargeHousehold'
        WHEN hd.hd_dep_count = 3  THEN 'MediumHousehold'
        ELSE 'SmallHousehold'
    END                                               AS household_size_category,
    (
        SELECT AVG(ss2.ss_ext_list_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    )                                                  AS avg_store_list_price
FROM sales_cte sf
JOIN store s ON sf.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON sf.ss_hdemo_sk = hd.hd_demo_sk
JOIN time_dim td ON sf.ss_sold_time_sk = td.t_time_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = sf.ss_ticket_number
    AND sr.sr_item_sk = sf.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
WHERE s.s_state = 'TX'
  AND s.s_gmt_offset = -6.00
  AND hd.hd_dep_count BETWEEN 2 AND 4
  AND td.t_hour BETWEEN 9 AND 17
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = sf.ss_ticket_number
          AND sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_quantity > 0
    )
GROUP BY
    s.s_store_id,
    s.s_state,
    td.t_hour,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    s.s_store_sk
ORDER BY total_net_paid DESC
LIMIT 100
