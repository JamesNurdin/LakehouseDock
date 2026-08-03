WITH sales_data AS (
    SELECT
        cs.cs_sold_time_sk      AS time_sk,
        cs.cs_bill_customer_sk  AS customer_sk,
        cs.cs_item_sk           AS item_sk,
        cs.cs_promo_sk          AS promo_sk,
        cs.cs_ship_mode_sk      AS ship_mode_sk,
        cs.cs_call_center_sk    AS call_center_sk,
        cs.cs_net_profit        AS net_profit,
        cs.cs_ext_discount_amt  AS discount_amt
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        NULL AS ship_mode_sk,
        NULL AS call_center_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt
    FROM store_sales ss
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    i.i_item_id,
    p.p_promo_name,
    sm.sm_type,
    cc.cc_name,
    td.t_time,
    ib.ib_lower_bound,
    cd.cd_education_status,
    SUM(s.discount_amt)               AS total_discount,
    SUM(s.net_profit)                 AS total_profit,
    COUNT(*)                          AS txn_count,
    ROW_NUMBER() OVER (
        PARTITION BY c.c_customer_id
        ORDER BY SUM(s.net_profit) DESC
    )                                 AS profit_rank,
    CASE
        WHEN SUM(s.net_profit) > (
            SELECT AVG(net_profit)
            FROM (
                SELECT cs.cs_net_profit AS net_profit FROM catalog_sales cs
                UNION ALL
                SELECT ss.ss_net_profit      FROM store_sales ss
            ) sub
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END                               AS profit_vs_avg
FROM sales_data s
JOIN time_dim td               ON s.time_sk = td.t_time_sk
JOIN customer c                ON s.customer_sk = c.c_customer_sk
JOIN customer_address ca       ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i                    ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p          ON s.promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm         ON s.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN call_center cc       ON s.call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_returns cr   ON cr.cr_returning_customer_sk = c.c_customer_sk
LEFT JOIN reason r              ON cr.cr_reason_sk = r.r_reason_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
    )
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
    )
  AND ib.ib_lower_bound > 50000
  AND cd.cd_education_status = 'Advanced Degree'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    c.c_customer_id,
    ca.ca_city,
    i.i_item_id,
    p.p_promo_name,
    sm.sm_type,
    cc.cc_name,
    td.t_time,
    ib.ib_lower_bound,
    cd.cd_education_status
HAVING SUM(s.net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
