WITH inventory_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year
),
sales_join AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        ss.ss_net_profit AS store_net_profit,
        cs.cs_net_profit AS catalog_net_profit,
        ca.ca_city,
        cd.cd_gender,
        p.p_discount_active,
        cp.cp_department,
        cc.cc_name AS call_center_name,
        ws.web_site_id,
        w.w_warehouse_name,
        c.c_customer_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_wp.d_date_sk
    JOIN date_dim d_cc ON cc.cc_open_date_sk = d_cc.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_customer_sk = c.c_customer_sk
          AND cs2.cs_ship_date_sk = d.d_date_sk
          AND cs2.cs_item_sk = i.i_item_sk
    )
      AND d.d_year = 2001
),
final AS (
    SELECT
        sj.s_store_id,
        sj.s_store_name,
        sj.i_product_name,
        sj.d_year,
        SUM(sj.store_net_profit) AS total_store_net_profit,
        SUM(sj.catalog_net_profit) AS total_catalog_net_profit,
        COALESCE(MAX(ia.total_quantity_on_hand), 0) AS total_quantity_on_hand,
        SUM(sj.store_net_profit + sj.catalog_net_profit) AS total_combined_profit
    FROM sales_join sj
    LEFT JOIN inventory_agg ia
        ON sj.i_item_sk = ia.i_item_sk
        AND sj.d_year = ia.d_year
    GROUP BY sj.s_store_id, sj.s_store_name, sj.i_product_name, sj.d_year
)
SELECT
    f.s_store_id,
    f.s_store_name,
    f.i_product_name,
    f.d_year,
    f.total_store_net_profit,
    f.total_catalog_net_profit,
    f.total_quantity_on_hand,
    f.total_combined_profit,
    SUM(f.total_combined_profit) OVER (
        PARTITION BY f.s_store_id
        ORDER BY f.d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_store,
    RANK() OVER (
        PARTITION BY f.d_year
        ORDER BY f.total_combined_profit DESC
    ) AS profit_rank_by_year
FROM final f
ORDER BY f.total_combined_profit DESC
LIMIT 100
