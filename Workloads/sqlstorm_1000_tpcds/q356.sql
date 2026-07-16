WITH sales_combined AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_store_sk AS store_sk,
        ss_customer_sk AS customer_sk,
        ss_item_sk AS item_sk,
        ss_promo_sk AS promo_sk,
        CAST(NULL AS integer) AS call_center_sk,
        ss_quantity AS quantity,
        ss_ext_discount_amt AS ext_discount_amt,
        ss_ext_sales_price AS ext_sales_price,
        ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss_net_profit AS net_profit,
        'store' AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        CAST(NULL AS integer),
        ws_bill_customer_sk,
        ws_item_sk,
        ws_promo_sk,
        CAST(NULL AS integer),
        ws_quantity,
        ws_ext_discount_amt,
        ws_ext_sales_price,
        ws_net_paid_inc_tax,
        ws_net_profit,
        'web'
    FROM web_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        CAST(NULL AS integer),
        cs_bill_customer_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_quantity,
        cs_ext_discount_amt,
        cs_ext_sales_price,
        cs_net_paid_inc_tax,
        cs_net_profit,
        'catalog'
    FROM catalog_sales
),
returns_combined AS (
    SELECT
        sr_returned_date_sk AS returned_date_sk,
        sr_store_sk AS store_sk,
        sr_item_sk AS item_sk,
        sr_return_quantity AS return_qty,
        sr_return_amt AS return_amt
    FROM store_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        CAST(NULL AS integer),
        wr_item_sk,
        wr_return_quantity,
        wr_return_amt
    FROM web_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        CAST(NULL AS integer),
        cr_item_sk,
        cr_return_quantity,
        cr_return_amount
    FROM catalog_returns
),
sales_enriched AS (
    SELECT
        sc.*,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        format_datetime(d.d_date, 'yyyy-MM') AS month_year,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        p.p_promo_name,
        p.p_cost AS promo_cost,
        cc.cc_name AS call_center_name,
        COALESCE(cc.cc_gmt_offset, 0) AS call_center_gmt_offset
    FROM sales_combined sc
    LEFT JOIN date_dim d ON sc.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON sc.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON sc.promo_sk = p.p_promo_sk
        AND sc.sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN call_center cc ON sc.call_center_sk = cc.cc_call_center_sk
),
item_sales AS (
    SELECT
        se.*,
        (SELECT COALESCE(SUM(rc.return_qty), 0)
         FROM returns_combined rc
         LEFT JOIN date_dim rd ON rc.returned_date_sk = rd.d_date_sk
         WHERE rc.item_sk = se.item_sk
           AND rc.returned_date_sk >= se.sold_date_sk
           AND format_datetime(rd.d_date, 'yyyy-MM') = se.month_year
        ) AS returns_after_sale,
        ROW_NUMBER() OVER (PARTITION BY se.store_sk, se.month_year ORDER BY se.net_profit DESC) AS profit_rank,
        SUM(se.net_paid_inc_tax) OVER (PARTITION BY se.store_sk, se.month_year ORDER BY se.sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
        CASE WHEN se.net_profit < 0 THEN 'loss' ELSE 'profit' END AS profit_status,
        CONCAT(se.i_item_id, ':', se.i_brand) AS item_key,
        COALESCE(se.promo_cost, 0) AS promo_discount,
        COALESCE(se.call_center_gmt_offset, 0) AS cc_gmt_offset
    FROM sales_enriched se
),
aggregated AS (
    SELECT
        store_sk,
        month_year,
        profit_status,
        SUM(net_paid_inc_tax) AS total_net_paid,
        SUM(net_profit) AS total_profit,
        SUM(ext_discount_amt) AS total_discount,
        SUM(ext_sales_price) AS total_sales,
        SUM(promo_discount) AS total_promo_discount,
        SUM(ext_discount_amt) / NULLIF(SUM(ext_sales_price), 0) AS avg_discount_rate,
        COUNT(DISTINCT item_sk) AS distinct_items_sold,
        SUM(returns_after_sale) AS total_returns_quantity
    FROM item_sales
    GROUP BY GROUPING SETS ((store_sk, month_year, profit_status), (store_sk, month_year))
),
top_items AS (
    SELECT
        store_sk,
        month_year,
        item_sk,
        i_item_id,
        i_product_name,
        net_profit,
        profit_rank
    FROM item_sales
    WHERE profit_rank <= 3
),
final_results AS (
    SELECT
        COALESCE(st.s_store_id, 'UNKNOWN') AS store_id,
        a.month_year,
        a.total_net_paid,
        a.total_profit,
        a.total_discount,
        a.total_sales,
        a.total_promo_discount,
        a.avg_discount_rate,
        a.distinct_items_sold,
        a.total_returns_quantity,
        ti.item_sk,
        ti.i_item_id,
        ti.i_product_name,
        ti.net_profit AS item_net_profit,
        ti.profit_rank
    FROM aggregated a
    LEFT JOIN store st ON a.store_sk = st.s_store_sk
    LEFT JOIN top_items ti ON a.store_sk = ti.store_sk AND a.month_year = ti.month_year
    WHERE a.profit_status IS NULL
),
month_list AS (
    SELECT DISTINCT format_datetime(d.d_date, 'yyyy-MM') AS month_year
    FROM date_dim d
),
unsold_items AS (
    SELECT i.i_item_sk AS item_sk, i.i_item_id, i.i_product_name
    FROM item i
    EXCEPT
    SELECT DISTINCT se.item_sk, se.i_item_id, se.i_product_name
    FROM sales_enriched se
),
unsold_month_items AS (
    SELECT ml.month_year, ui.item_sk, ui.i_item_id, ui.i_product_name
    FROM month_list ml
    CROSS JOIN unsold_items ui
)
SELECT *
FROM final_results
UNION ALL
SELECT
    'NO_SALES' AS store_id,
    um.month_year,
    CAST(0 AS double) AS total_net_paid,
    CAST(0 AS double) AS total_profit,
    CAST(0 AS double) AS total_discount,
    CAST(0 AS double) AS total_sales,
    CAST(0 AS double) AS total_promo_discount,
    NULL AS avg_discount_rate,
    0 AS distinct_items_sold,
    0 AS total_returns_quantity,
    um.item_sk,
    um.i_item_id,
    um.i_product_name,
    CAST(0 AS double) AS item_net_profit,
    NULL AS profit_rank
FROM unsold_month_items um
