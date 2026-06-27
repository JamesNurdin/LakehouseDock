WITH
    store_sales_pre AS (
        SELECT
            ss_item_sk      AS item_sk,
            ss_hdemo_sk    AS hdemo_sk,
            ss_customer_sk AS customer_sk,
            ss_quantity    AS quantity,
            ss_net_paid    AS net_paid,
            ss_net_profit  AS net_profit
        FROM store_sales
    ),
    web_sales_pre AS (
        SELECT
            ws_item_sk      AS item_sk,
            ws_bill_hdemo_sk AS hdemo_sk,
            ws_bill_customer_sk AS customer_sk,
            ws_quantity    AS quantity,
            ws_net_paid    AS net_paid,
            ws_net_profit  AS net_profit
        FROM web_sales
    ),
    catalog_sales_pre AS (
        SELECT
            cs_item_sk      AS item_sk,
            cs_bill_hdemo_sk AS hdemo_sk,
            cs_bill_customer_sk AS customer_sk,
            cs_quantity    AS quantity,
            cs_net_paid    AS net_paid,
            cs_net_profit  AS net_profit
        FROM catalog_sales
    ),
    combined_sales AS (
        SELECT * FROM store_sales_pre
        UNION ALL
        SELECT * FROM web_sales_pre
        UNION ALL
        SELECT * FROM catalog_sales_pre
    )
SELECT
    i.i_category                         AS product_category,
    ib.ib_lower_bound                    AS income_lower,
    ib.ib_upper_bound                    AS income_upper,
    SUM(cs.quantity)                     AS total_quantity,
    SUM(cs.net_paid)                     AS total_net_paid,
    SUM(cs.net_profit)                   AS total_net_profit,
    COUNT(DISTINCT cs.customer_sk)       AS distinct_customers,
    ROUND(SUM(cs.net_profit) / NULLIF(SUM(cs.quantity), 0), 2) AS avg_profit_per_unit
FROM combined_sales cs
JOIN item i
    ON cs.item_sk = i.i_item_sk
JOIN household_demographics hd
    ON cs.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer c
    ON cs.customer_sk = c.c_customer_sk
WHERE cs.quantity > 0
GROUP BY i.i_category, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY i.i_category, ib.ib_lower_bound
