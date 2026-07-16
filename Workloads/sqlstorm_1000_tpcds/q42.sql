WITH
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        st.s_store_name AS region_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_brand, st.s_store_name
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        w.web_name AS region_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_brand, w.web_name
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(cs.cs_quantity) AS quantity,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
        cc.cc_name AS region_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_brand, cc.cc_name
),
combined_sales AS (
    SELECT *, 'store' AS channel FROM store_sales_agg
    UNION ALL
    SELECT *, 'web' AS channel FROM web_sales_agg
    UNION ALL
    SELECT *, 'catalog' AS channel FROM catalog_sales_agg
),
ranked_sales AS (
    SELECT
        year,
        month_seq,
        channel,
        region_name,
        item_id,
        product_name,
        category,
        brand,
        quantity,
        net_paid,
        net_profit,
        avg_discount,
        unique_customers,
        ROW_NUMBER() OVER (PARTITION BY year, month_seq, channel ORDER BY net_profit DESC) AS profit_rank
    FROM combined_sales
)
SELECT
    year,
    month_seq,
    channel,
    region_name,
    item_id,
    product_name,
    category,
    brand,
    quantity,
    net_paid,
    net_profit,
    avg_discount,
    unique_customers,
    profit_rank
FROM ranked_sales
WHERE profit_rank <= 10
ORDER BY year, month_seq, channel, profit_rank
