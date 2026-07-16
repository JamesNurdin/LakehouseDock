WITH all_sales AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        'store' AS channel,
        ss_store_sk AS location_sk,
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_net_paid_inc_tax AS net_paid,
        ss_net_profit AS profit,
        ss_ext_discount_amt AS discount_amount,
        ss_cdemo_sk AS cdemo_sk
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk AS date_sk,
        'catalog' AS channel,
        cs_call_center_sk AS location_sk,
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_net_paid_inc_tax AS net_paid,
        cs_net_profit AS profit,
        cs_ext_discount_amt AS discount_amount,
        cs_bill_cdemo_sk AS cdemo_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk AS date_sk,
        'web' AS channel,
        ws_web_page_sk AS location_sk,
        ws_item_sk AS item_sk,
        ws_quantity AS quantity,
        ws_net_paid_inc_tax AS net_paid,
        ws_net_profit AS profit,
        ws_ext_discount_amt AS discount_amount,
        ws_bill_cdemo_sk AS cdemo_sk
    FROM web_sales
),
sales_enriched AS (
    SELECT
        a.channel,
        d.d_year,
        d.d_moy AS month_of_year,
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(a.quantity) AS total_quantity,
        SUM(a.net_paid) AS total_net_paid,
        SUM(a.profit) AS total_profit,
        AVG(CASE WHEN a.quantity = 0 THEN 0 ELSE a.discount_amount / a.quantity END) AS avg_discount_per_item
    FROM all_sales a
    JOIN date_dim d ON a.date_sk = d.d_date_sk
    JOIN item i ON a.item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON a.cdemo_sk = cd.cd_demo_sk
    GROUP BY
        a.channel,
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    channel,
    d_year,
    month_of_year,
    i_category,
    i_brand,
    cd_gender,
    cd_marital_status,
    total_quantity,
    total_net_paid,
    total_profit,
    avg_discount_per_item,
    RANK() OVER (PARTITION BY channel, d_year, month_of_year ORDER BY total_profit DESC) AS profit_rank
FROM sales_enriched
WHERE total_profit > 0
ORDER BY channel, d_year, month_of_year, profit_rank
LIMIT 200
