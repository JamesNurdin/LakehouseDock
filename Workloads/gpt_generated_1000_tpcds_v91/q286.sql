WITH
    date_filtered AS (
        SELECT d_date_sk,
               d_date,
               d_year,
               d_month_seq,
               d_week_seq
        FROM date_dim
        WHERE d_year = 2001
    ),
    store_sales_agg AS (
        SELECT
            d.d_date_sk,
            SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
            SUM(ss.ss_quantity) AS total_store_qty
        FROM store_sales ss
        JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
        JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
        JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
        WHERE p_ss.p_discount_active = 'Y'
          AND ca_ss.ca_state = 'CA'
        GROUP BY d.d_date_sk
    ),
    catalog_sales_agg AS (
        SELECT
            d.d_date_sk,
            w.w_warehouse_sk,
            SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
            SUM(CASE WHEN sm.sm_code = 'AIR' THEN cs.cs_ext_sales_price ELSE 0 END) AS total_air_sales
        FROM catalog_sales cs
        JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
        JOIN customer c_cs ON cs.cs_bill_customer_sk = c_cs.c_customer_sk
        JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
        JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
        WHERE sm.sm_code IN ('AIR', 'SEA')
          AND cs.cs_quantity > 5
          AND cc.cc_gmt_offset > -5
        GROUP BY d.d_date_sk, w.w_warehouse_sk
    ),
    store_returns_agg AS (
        SELECT
            d.d_date_sk,
            SUM(sr.sr_net_loss) AS total_returns_loss
        FROM store_returns sr
        JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        GROUP BY d.d_date_sk
    ),
    inventory_agg AS (
        SELECT
            d.d_date_sk,
            i.inv_warehouse_sk,
            SUM(i.inv_quantity_on_hand) AS total_inventory_qty
        FROM inventory i
        JOIN date_filtered d ON i.inv_date_sk = d.d_date_sk
        JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
        GROUP BY d.d_date_sk, i.inv_warehouse_sk
    ),
    store_ids_for_analysis AS (
        SELECT DISTINCT s.s_store_id
        FROM store s
        JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
        JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
        EXCEPT
        SELECT DISTINCT s.s_store_id
        FROM store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    )
SELECT DISTINCT
    d.d_date,
    ss_agg.total_store_sales,
    cs_agg.total_catalog_sales,
    cs_agg.total_air_sales,
    COALESCE(sr_agg.total_returns_loss, 0) AS total_returns_loss,
    (ss_agg.total_store_sales + cs_agg.total_catalog_sales - COALESCE(sr_agg.total_returns_loss, 0)) AS net_revenue,
    inv_agg.total_inventory_qty,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_discounted_promo_cost,
    ROW_NUMBER() OVER (ORDER BY (ss_agg.total_store_sales + cs_agg.total_catalog_sales - COALESCE(sr_agg.total_returns_loss, 0)) DESC) AS overall_rank
FROM date_filtered d
LEFT JOIN store_sales_agg ss_agg ON ss_agg.d_date_sk = d.d_date_sk
LEFT JOIN catalog_sales_agg cs_agg ON cs_agg.d_date_sk = d.d_date_sk
LEFT JOIN inventory_agg inv_agg ON inv_agg.d_date_sk = d.d_date_sk
                               AND inv_agg.inv_warehouse_sk = cs_agg.w_warehouse_sk
LEFT JOIN store_returns_agg sr_agg ON sr_agg.d_date_sk = d.d_date_sk
WHERE d.d_month_seq BETWEEN 1200 AND 1211
  AND EXISTS (SELECT 1 FROM store_ids_for_analysis si WHERE si.s_store_id IS NOT NULL)
ORDER BY net_revenue DESC
LIMIT 100
