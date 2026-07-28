WITH joined AS (
    SELECT
        d_sold.d_year,
        i.i_category,
        i.i_brand,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        inv.inv_quantity_on_hand,
        hd.hd_income_band_sk,
        p.p_discount_active,
        sm.sm_type,
        wp.wp_url,
        cp.cp_type
    FROM catalog_sales cs
    JOIN date_dim d_sold          ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship          ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss           ON ss.ss_item_sk = i.i_item_sk
                                   AND ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN web_page wp              ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_closed        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_sold.d_year = 2002
      AND i.i_current_price > 100
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'homepage'
),
agg AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(cs_net_profit + ss_net_profit) AS total_net_profit,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS txn_cnt,
        SUM(CASE WHEN p_discount_active = 'Y' THEN cs_ext_sales_price ELSE 0 END) AS discount_sales,
        SUM(CASE WHEN sm_type = 'AIR' THEN 1 ELSE 0 END) AS air_shipments
    FROM joined
    GROUP BY GROUPING SETS (
        (d_year, i_category, i_brand),
        (d_year, i_category),
        (d_year),
        ()
    )
    HAVING SUM(cs_ext_sales_price) > 1000
       AND SUM(ss_ext_sales_price) > 500
       AND COUNT(*) > 5
)
SELECT
    d_year,
    i_category,
    i_brand,
    total_catalog_sales,
    total_store_sales,
    total_net_profit,
    total_inventory,
    txn_cnt,
    discount_sales,
    air_shipments,
    SUM(total_net_profit) OVER (PARTITION BY d_year ORDER BY i_category ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_year,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year DESC, i_category, i_brand NULLS LAST
