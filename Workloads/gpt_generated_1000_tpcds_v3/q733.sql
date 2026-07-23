WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt
    FROM
        item i
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        cc.cc_manager = 'Mark Hightower'
        AND i.i_size IN ('small', 'medium')
        AND p.p_cost < 5000
        AND ss.ss_quantity > 1
        AND cs.cs_quantity > 0
        AND i.i_current_price > 20
    GROUP BY
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        p.p_promo_sk,
        p.p_promo_name
)
SELECT
    i_category,
    i_brand,
    COUNT(*) AS num_items,
    SUM(total_store_sales) AS sum_store_sales,
    SUM(total_catalog_sales) AS sum_catalog_sales,
    SUM(total_store_profit + total_catalog_profit - total_returns) AS net_combined_profit,
    AVG(total_store_profit + total_catalog_profit - total_returns) AS avg_item_profit
FROM
    sales_agg
WHERE
    total_store_sales > 1000
    AND total_catalog_sales > 500
GROUP BY
    i_category,
    i_brand
HAVING
    SUM(total_store_profit + total_catalog_profit - total_returns) > 0
ORDER BY
    net_combined_profit DESC
LIMIT 100
