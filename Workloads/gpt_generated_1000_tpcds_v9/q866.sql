WITH store_sales_agg AS (
    SELECT
        i.i_item_sk,
        dd.d_year,
        dd.d_moy,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_promo_sk) AS store_distinct_promo_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE dd.d_year = 2000
      AND i.i_category = 'Furniture'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_sk, dd.d_year, dd.d_moy
),
catalog_sales_agg AS (
    SELECT
        i.i_item_sk,
        dd.d_year,
        dd.d_moy,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_promo_sk) AS catalog_distinct_promo_cnt,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE dd.d_year = 2000
      AND i.i_category = 'Furniture'
      AND w.w_state = 'CA'
      AND cc.cc_country = 'USA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_sk, dd.d_year, dd.d_moy
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        dd.d_year,
        dd.d_moy,
        SUM(wr.wr_net_loss) AS returns_net_loss,
        COUNT(*) AS returns_cnt,
        COUNT(DISTINCT r.r_reason_sk) AS distinct_return_reason_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE dd.d_year = 2000
      AND i.i_category = 'Furniture'
    GROUP BY i.i_item_sk, dd.d_year, dd.d_moy
),
inventory_agg AS (
    SELECT
        i.i_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim dd ON inv.inv_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2000
      AND w.w_state = 'CA'
    GROUP BY i.i_item_sk
),
combined_sales AS (
    SELECT
        COALESCE(ss.i_item_sk, cs.i_item_sk, wr.i_item_sk) AS i_item_sk,
        COALESCE(ss.d_year, cs.d_year, wr.d_year) AS d_year,
        COALESCE(ss.d_moy, cs.d_moy, wr.d_moy) AS d_moy,
        ss.store_net_paid,
        ss.store_net_profit,
        ss.store_distinct_promo_cnt,
        cs.catalog_net_paid,
        cs.catalog_net_profit,
        cs.catalog_distinct_promo_cnt,
        cs.catalog_sales_cnt,
        wr.returns_net_loss,
        wr.returns_cnt,
        wr.distinct_return_reason_cnt
    FROM store_sales_agg ss
    FULL OUTER JOIN catalog_sales_agg cs
        ON ss.i_item_sk = cs.i_item_sk
        AND ss.d_year = cs.d_year
        AND ss.d_moy = cs.d_moy
    FULL OUTER JOIN returns_agg wr
        ON COALESCE(ss.i_item_sk, cs.i_item_sk) = wr.i_item_sk
        AND COALESCE(ss.d_year, cs.d_year) = wr.d_year
        AND COALESCE(ss.d_moy, cs.d_moy) = wr.d_moy
)
SELECT DISTINCT
    i.i_item_id,
    i.i_product_name,
    cs.d_year AS year,
    cs.d_moy AS month,
    cs.store_net_paid,
    cs.store_net_profit,
    cs.catalog_net_paid,
    cs.catalog_net_profit,
    COALESCE(cs.returns_net_loss, 0) AS returns_net_loss,
    (COALESCE(cs.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) - COALESCE(cs.returns_net_loss, 0)) AS total_profit,
    inventory_agg.avg_inventory,
    (SELECT AVG(inv2.inv_quantity_on_hand) FROM inventory inv2 WHERE inv2.inv_item_sk = i.i_item_sk) AS avg_inventory_scalar,
    COALESCE(cs.store_distinct_promo_cnt, 0) AS store_distinct_promo_cnt,
    COALESCE(cs.catalog_distinct_promo_cnt, 0) AS catalog_distinct_promo_cnt,
    COALESCE(cs.distinct_return_reason_cnt, 0) AS distinct_return_reason_cnt,
    RANK() OVER (PARTITION BY cs.d_year, cs.d_moy ORDER BY (COALESCE(cs.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) - COALESCE(cs.returns_net_loss, 0)) DESC) AS profit_rank
FROM combined_sales cs
JOIN item i ON cs.i_item_sk = i.i_item_sk
LEFT JOIN inventory_agg ON i.i_item_sk = inventory_agg.i_item_sk
WHERE cs.store_net_paid IS NOT NULL OR cs.catalog_net_paid IS NOT NULL
ORDER BY year, month, profit_rank
LIMIT 100
