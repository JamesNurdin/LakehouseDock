WITH
sales_union AS (
    SELECT 'store' AS sales_channel,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_profit AS profit,
           ss.ss_net_paid AS net_paid,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_store_sk AS store_sk,
           ss.ss_promo_sk AS promo_sk,
           NULL AS call_center_sk,
           NULL AS web_page_sk
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog' AS sales_channel,
           cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_bill_customer_sk,
           cs.cs_quantity,
           cs.cs_net_profit,
           cs.cs_net_paid,
           cs.cs_ext_sales_price,
           NULL,
           cs.cs_promo_sk,
           cs.cs_call_center_sk,
           NULL
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web' AS sales_channel,
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_net_profit,
           ws.ws_net_paid,
           ws.ws_ext_sales_price,
           NULL,
           ws.ws_promo_sk,
           NULL,
           ws.ws_web_page_sk
    FROM web_sales ws
),
sales_by_month_category AS (
    SELECT
        d.d_year,
        d.d_moy AS d_month,
        i.i_category,
        i.i_category_id,
        s.sales_channel,
        COALESCE(st.s_store_name, cc.cc_name, wp.wp_type) AS channel_desc,
        SUM(s.quantity) AS total_quantity,
        SUM(s.profit) AS total_profit,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.ext_sales_price) AS total_ext_sales,
        AVG(CASE WHEN s.quantity = 0 THEN NULL ELSE s.net_paid / s.quantity END) AS avg_price_per_item,
        COUNT(DISTINCT s.customer_sk) AS distinct_customers
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    LEFT JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON s.web_page_sk = wp.wp_web_page_sk
    GROUP BY
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_category_id,
        s.sales_channel,
        COALESCE(st.s_store_name, cc.cc_name, wp.wp_type)
),
customer_repeat AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        i.i_category,
        COUNT(*) AS purchase_count,
        MAX(d.d_date) AS most_recent_purchase
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    WHERE s.quantity > 0
    GROUP BY c.c_customer_sk, i.i_category
    HAVING COUNT(*) >= 3
)
SELECT
    ranked.d_year,
    ranked.d_month,
    ranked.i_category,
    ranked.sales_channel,
    ranked.channel_desc,
    ranked.channel_label,
    ranked.total_quantity,
    ranked.total_profit,
    ranked.total_net_paid,
    ranked.total_ext_sales,
    ranked.avg_price_per_item,
    ranked.distinct_customers,
    ranked.profit_rank,
    CASE
        WHEN ranked.profit_rank <= 3 THEN 'Top3'
        WHEN ranked.profit_rank <= 10 THEN 'Top10'
        ELSE 'Other'
    END AS rank_group,
    ranked.profit_adj,
    ranked.profit_margin,
    ranked.prior_month_profit,
    ranked.repeat_customer_count,
    ranked.final_channel_desc
FROM (
    SELECT
        sbmc.d_year,
        sbmc.d_month,
        sbmc.i_category,
        sbmc.sales_channel,
        sbmc.channel_desc,
        CONCAT(sbmc.channel_desc, ': ', sbmc.sales_channel) AS channel_label,
        sbmc.total_quantity,
        sbmc.total_profit,
        sbmc.total_net_paid,
        sbmc.total_ext_sales,
        sbmc.avg_price_per_item,
        sbmc.distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY sbmc.d_year, sbmc.d_month, sbmc.sales_channel ORDER BY sbmc.total_profit DESC) AS profit_rank,
        sbmc.total_profit - COALESCE(sbmc.total_quantity, 0) * 0.01 AS profit_adj,
        CASE WHEN sbmc.total_ext_sales = 0 THEN NULL ELSE sbmc.total_profit / sbmc.total_ext_sales END AS profit_margin,
        LAG(sbmc.total_profit) OVER (PARTITION BY sbmc.i_category ORDER BY sbmc.d_year, sbmc.d_month) AS prior_month_profit,
        (SELECT COUNT(*) FROM customer_repeat cr WHERE cr.i_category = sbmc.i_category) AS repeat_customer_count,
        COALESCE(sbmc.channel_desc, 'UNKNOWN') AS final_channel_desc
    FROM sales_by_month_category sbmc
) ranked
WHERE ranked.profit_rank <= 20
ORDER BY ranked.d_year, ranked.d_month, ranked.profit_rank
