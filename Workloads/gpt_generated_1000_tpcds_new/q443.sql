WITH
    ss_agg AS (
        SELECT
            ss.ss_cdemo_sk,
            SUM(ss.ss_ext_sales_price) AS total_ss_sales,
            SUM(ss.ss_net_profit)    AS total_ss_profit
        FROM store_sales ss
        WHERE ss.ss_quantity > 1
          AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY ss.ss_cdemo_sk
    ),
    cs_union AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_ship_mode_sk,
            cs.cs_ext_sales_price,
            cs.cs_ext_discount_amt
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 0
          AND cs.cs_ext_sales_price > 500
          AND cs.cs_ext_discount_amt > 0
        UNION
        SELECT
            ws.ws_item_sk,
            ws.ws_ship_mode_sk,
            ws.ws_ext_sales_price,
            ws.ws_ext_discount_amt
        FROM web_sales ws
        WHERE ws.ws_quantity >= 2
          AND ws.ws_ext_sales_price > 500
          AND ws.ws_ext_discount_amt > 0
    ),
    full_sales_returns AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_cdemo_sk,
            ss.ss_ticket_number,
            ss.ss_ext_sales_price,
            sr.sr_returned_date_sk,
            sr.sr_item_sk        AS sr_item_sk,
            sr.sr_cdemo_sk,
            sr.sr_return_amt,
            sr.sr_net_loss
        FROM store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_item_sk = sr.sr_item_sk
           AND ss.ss_ticket_number = sr.sr_ticket_number
    )
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    sm.sm_ship_mode_id,
    sm.sm_type,
    cu.cs_item_sk,
    cu.cs_ext_sales_price,
    cu.cs_ext_discount_amt,
    agg.total_ss_sales,
    agg.total_ss_profit,
    fs.ss_ext_sales_price,
    fs.sr_return_amt,
    fs.sr_net_loss,
    (COALESCE(agg.total_ss_profit, 0) - COALESCE(fs.sr_net_loss, 0) + cu.cs_ext_sales_price) AS combined_metric,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY (COALESCE(agg.total_ss_profit, 0) - COALESCE(fs.sr_net_loss, 0) + cu.cs_ext_sales_price) DESC) AS gender_rank,
    cs_sum.total_by_ship_mode
FROM cs_union cu
JOIN ship_mode sm
    ON cu.cs_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN LATERAL (
    SELECT SUM(c2.cs_ext_sales_price) AS total_by_ship_mode
    FROM catalog_sales c2
    WHERE c2.cs_ship_mode_sk = cu.cs_ship_mode_sk
) cs_sum
LEFT JOIN full_sales_returns fs
    ON cu.cs_item_sk = fs.ss_item_sk
LEFT JOIN ss_agg agg
    ON fs.ss_cdemo_sk = agg.ss_cdemo_sk
LEFT JOIN customer_demographics cd
    ON agg.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_purchase_estimate BETWEEN 4000 AND 9000
  AND cd.cd_dep_employed_count >= 2
  AND sm.sm_type = 'AIR'
  AND cu.cs_ext_sales_price > 1000
ORDER BY combined_metric DESC
OFFSET 10 LIMIT 100
