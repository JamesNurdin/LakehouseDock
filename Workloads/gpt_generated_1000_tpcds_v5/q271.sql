WITH
    cat_agg AS (
        SELECT
            cs_call_center_sk,
            cs_promo_sk,
            cs_catalog_page_sk,
            cs_ship_mode_sk,
            cs_sold_time_sk,
            SUM(cs_net_paid) AS cat_net_paid,
            COUNT(*) AS cat_orders
        FROM catalog_sales
        WHERE cs_quantity > 0
        GROUP BY cs_call_center_sk, cs_promo_sk, cs_catalog_page_sk, cs_ship_mode_sk, cs_sold_time_sk
    ),
    store_agg AS (
        SELECT
            ss_sold_time_sk,
            ss_promo_sk,
            SUM(ss_net_paid) AS store_net_paid,
            COUNT(*) AS store_transactions
        FROM store_sales
        WHERE ss_quantity > 0
        GROUP BY ss_sold_time_sk, ss_promo_sk
    )
SELECT
    cc.cc_name,
    p_cat.p_purpose,
    cp.cp_catalog_page_number,
    sm.sm_type,
    td_cat.t_hour,
    cat_agg.cat_net_paid,
    cat_agg.cat_orders,
    store_agg.store_net_paid,
    store_agg.store_transactions,
    SUM(wr.wr_net_loss) AS total_return_loss
FROM cat_agg
JOIN call_center cc
    ON cat_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p_cat
    ON cat_agg.cs_promo_sk = p_cat.p_promo_sk
JOIN catalog_page cp
    ON cat_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cat_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_cat
    ON cat_agg.cs_sold_time_sk = td_cat.t_time_sk
JOIN store_agg
    ON cat_agg.cs_sold_time_sk = store_agg.ss_sold_time_sk
JOIN promotion p_store
    ON store_agg.ss_promo_sk = p_store.p_promo_sk
JOIN time_dim td_store
    ON store_agg.ss_sold_time_sk = td_store.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td_store.t_time_sk
JOIN time_dim td_return
    ON wr.wr_returned_time_sk = td_return.t_time_sk
WHERE
    td_cat.t_hour BETWEEN 8 AND 20
    AND p_cat.p_purpose = 'Unknown'
    AND p_store.p_channel_email = 'N'
GROUP BY
    cc.cc_name,
    p_cat.p_purpose,
    cp.cp_catalog_page_number,
    sm.sm_type,
    td_cat.t_hour,
    cat_agg.cat_net_paid,
    cat_agg.cat_orders,
    store_agg.store_net_paid,
    store_agg.store_transactions
ORDER BY
    cat_agg.cat_net_paid DESC
LIMIT 100
