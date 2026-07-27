WITH catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk                AS item_sk,
        cs.cs_sold_date_sk           AS date_sk,
        SUM(cs.cs_net_profit)        AS catalog_profit,
        COUNT(*)                     AS catalog_cnt,
        MIN(cs.cs_ship_mode_sk)      AS ship_mode_sk,
        MIN(cs.cs_warehouse_sk)      AS warehouse_sk,
        MIN(cs.cs_bill_addr_sk)      AS bill_addr_sk,
        MIN(cs.cs_bill_cdemo_sk)     AS bill_cdemo_sk,
        MIN(cs.cs_bill_hdemo_sk)     AS bill_hdemo_sk,
        MIN(cs.cs_promo_sk)          AS promo_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk                AS item_sk,
        ws.ws_sold_date_sk           AS date_sk,
        SUM(ws.ws_net_profit)        AS web_profit,
        COUNT(*)                     AS web_cnt,
        MIN(ws.ws_ship_mode_sk)      AS ship_mode_sk,
        MIN(ws.ws_warehouse_sk)      AS warehouse_sk,
        MIN(ws.ws_bill_addr_sk)      AS bill_addr_sk,
        MIN(ws.ws_bill_cdemo_sk)     AS bill_cdemo_sk,
        MIN(ws.ws_bill_hdemo_sk)     AS bill_hdemo_sk,
        MIN(ws.ws_promo_sk)          AS promo_sk,
        MIN(ws.ws_web_site_sk)       AS web_site_sk
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
),
combined_sales AS (
    SELECT
        COALESCE(cs.item_sk, ws.item_sk)                AS item_sk,
        COALESCE(cs.date_sk, ws.date_sk)                AS date_sk,
        COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0)   AS total_profit,
        COALESCE(cs.catalog_cnt, 0) + COALESCE(ws.web_cnt, 0)         AS total_cnt,
        COALESCE(cs.ship_mode_sk, ws.ship_mode_sk)      AS ship_mode_sk,
        COALESCE(cs.warehouse_sk, ws.warehouse_sk)      AS warehouse_sk,
        COALESCE(cs.bill_addr_sk, ws.bill_addr_sk)      AS bill_addr_sk,
        COALESCE(cs.bill_cdemo_sk, ws.bill_cdemo_sk)    AS bill_cdemo_sk,
        COALESCE(cs.bill_hdemo_sk, ws.bill_hdemo_sk)    AS bill_hdemo_sk,
        COALESCE(cs.promo_sk, ws.promo_sk)              AS promo_sk,
        ws.web_site_sk                                 AS web_site_sk
    FROM catalog_sales_agg cs
    FULL OUTER JOIN web_sales_agg ws
        ON cs.item_sk = ws.item_sk
       AND cs.date_sk = ws.date_sk
)
SELECT
    s.s_store_name,
    i.i_brand,
    d.d_year,
    d.d_month_seq,
    SUM(cs.total_profit)      AS total_profit,
    SUM(cs.total_cnt)         AS total_transactions,
    AVG(cs.total_profit)      AS avg_profit_per_transaction
FROM combined_sales cs
JOIN item i
    ON i.i_item_sk = cs.item_sk
JOIN date_dim d
    ON d.d_date_sk = cs.date_sk
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.ship_mode_sk
LEFT JOIN warehouse w
    ON w.w_warehouse_sk = cs.warehouse_sk
LEFT JOIN customer_address ca
    ON ca.ca_address_sk = cs.bill_addr_sk
LEFT JOIN customer_demographics cd
    ON cd.cd_demo_sk = cs.bill_cdemo_sk
LEFT JOIN household_demographics hd
    ON hd.hd_demo_sk = cs.bill_hdemo_sk
LEFT JOIN promotion p
    ON p.p_promo_sk = cs.promo_sk
LEFT JOIN web_site ws
    ON ws.web_site_sk = cs.web_site_sk
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = cs.item_sk
   AND inv.inv_date_sk = cs.date_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = cs.item_sk
   AND sr.sr_returned_date_sk = cs.date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = cs.item_sk
   AND wr.wr_returned_date_sk = cs.date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_current_price > 100
  AND s.s_tax_percentage BETWEEN 0.05 AND 0.10
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND hd.hd_income_band_sk IN (1, 2, 3)
GROUP BY s.s_store_name, i.i_brand, d.d_year, d.d_month_seq
HAVING SUM(cs.total_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
