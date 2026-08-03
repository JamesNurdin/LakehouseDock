WITH agg_sales AS (
    SELECT
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_price,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_level
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        i.i_category IN ('Electronics', 'Furniture')
        AND i.i_current_price BETWEEN 100 AND 1000
        AND p.p_discount_active = 'Y'
        AND inv.inv_quantity_on_hand > 0
        AND cd.cd_gender = 'F'
        AND ca.ca_country = 'United States'
    GROUP BY
        ss.ss_item_sk,
        i.i_category,
        i.i_brand
)
SELECT
    agg.i_category,
    agg.i_brand,
    agg.sales_level,
    agg.total_sales,
    agg.total_quantity,
    agg.avg_price,
    (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_item_sk = agg.ss_item_sk) AS return_count,
    LAG(agg.total_sales) OVER (PARTITION BY agg.i_category ORDER BY agg.total_sales DESC) AS prev_sales,
    SUM(agg.total_sales) OVER (PARTITION BY agg.i_category ORDER BY agg.total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM agg_sales agg
JOIN catalog_returns cr2
    ON cr2.cr_item_sk = agg.ss_item_sk
JOIN call_center cc
    ON cr2.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    cc.cc_state = 'CA'
    AND cp.cp_type = 'monthly'
    AND sm.sm_carrier = 'FEDEX'
    AND agg.ss_item_sk NOT IN (
        SELECT cr_inner.cr_item_sk
        FROM catalog_returns cr_inner
        WHERE cr_inner.cr_net_loss > 5000
    )
ORDER BY
    agg.i_category,
    agg.total_sales DESC
LIMIT 100
