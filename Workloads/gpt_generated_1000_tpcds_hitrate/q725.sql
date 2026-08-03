WITH sales_union AS (
    -- Store sales side
    SELECT
        ss.ss_store_sk               AS store_sk,
        s.s_store_name               AS store_name,
        ss.ss_item_sk                AS item_sk,
        i.i_category                 AS item_category,
        ss.ss_ext_sales_price        AS sales_amount,
        ss.ss_net_profit             AS net_profit,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_ext_sales_price > (
            SELECT AVG(ss2.ss_ext_sales_price)
            FROM store_sales ss2
            WHERE ss2.ss_sold_date_sk = 2450000
            LIMIT 1
          )
      AND EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_store_sk = ss.ss_store_sk
              AND sr.sr_item_sk = ss.ss_item_sk
          )
    UNION ALL
    -- Web sales side
    SELECT
        ws.ws_web_site_sk            AS store_sk,
        ws_site.web_name             AS store_name,
        ws.ws_item_sk                AS item_sk,
        i2.i_category                AS item_category,
        ws.ws_ext_sales_price        AS sales_amount,
        ws.ws_net_profit             AS net_profit,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    WHERE ws_site.web_country = 'United States'
      AND ws.ws_ext_sales_price > (
            SELECT AVG(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_sold_date_sk = 2450000
            LIMIT 1
          )
      AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
          )
)
SELECT
    su.store_sk,
    su.store_name,
    su.item_category,
    su.profit_flag,
    COUNT(DISTINCT su.store_sk) OVER ()          AS distinct_store_cnt,
    SUM(DISTINCT su.sales_amount) OVER ()       AS sum_distinct_sales,
    r.r_reason_desc,
    v.flag
FROM sales_union su
CROSS JOIN (
    SELECT r_reason_desc
    FROM reason
    WHERE r_reason_id = 'R001'
    LIMIT 1
) r
CROSS JOIN (
    VALUES ('X'), ('Y')
) AS v(flag)
ORDER BY su.sales_amount DESC
LIMIT 100
