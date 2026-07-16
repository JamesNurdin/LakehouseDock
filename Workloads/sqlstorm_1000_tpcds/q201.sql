WITH base_sales AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        d.d_year,
        d.d_month_seq,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS qty,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        cd.cd_gender AS gender,
        hd.hd_income_band_sk AS income_band_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
),
cat_sales AS (
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        d.d_year,
        d.d_month_seq,
        cs.cs_call_center_sk AS store_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS qty,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cd.cd_gender AS gender,
        hd.hd_income_band_sk AS income_band_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
),
web_sales_cte AS (
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        d.d_year,
        d.d_month_seq,
        ws.ws_warehouse_sk AS store_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS qty,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        cd.cd_gender AS gender,
        hd.hd_income_band_sk AS income_band_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
),
unified_sales AS (
    SELECT * FROM base_sales
    UNION ALL
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM web_sales_cte
),
aggregated_sales AS (
    SELECT
        channel,
        d_year,
        d_month_seq,
        store_sk,
        gender,
        income_band_sk,
        SUM(qty) AS total_qty,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amt) AS total_discount
    FROM unified_sales
    GROUP BY
        channel,
        d_year,
        d_month_seq,
        store_sk,
        gender,
        income_band_sk
    HAVING SUM(net_profit) > 0
)
SELECT
    channel,
    d_year,
    d_month_seq,
    store_sk,
    gender,
    income_band_sk,
    total_qty,
    total_net_paid,
    total_net_profit,
    total_discount,
    CASE WHEN total_net_profit <> 0 THEN total_discount / total_net_profit ELSE NULL END AS discount_to_profit_ratio,
    ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY total_net_profit DESC) AS profit_rank_year
FROM aggregated_sales
ORDER BY channel, d_year, d_month_seq, profit_rank_year
LIMIT 100
