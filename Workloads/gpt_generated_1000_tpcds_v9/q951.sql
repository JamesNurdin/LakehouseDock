WITH all_data AS (
    SELECT
        d_sold.d_year AS cs_year,
        d_ss_sold.d_year AS ss_year,
        s.s_store_name,
        cp.cp_department,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_net_profit AS store_net_profit,
        i_cs.i_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN store_sales ss ON ss.ss_item_sk = i_cs.i_item_sk
    JOIN customer c_sscust ON ss.ss_customer_sk = c_sscust.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN date_dim d_ss_sold ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i_cs.i_item_sk
    JOIN date_dim d_inv_date ON inv.inv_date_sk = d_inv_date.d_date_sk
    LEFT JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN customer_address ca_ss_addr ON ss.ss_addr_sk = ca_ss_addr.ca_address_sk
    WHERE cs.cs_net_profit IS NOT NULL
),
filtered_data AS (
    SELECT
        cs_year,
        ss_year,
        s_store_name,
        cp_department,
        catalog_net_profit,
        store_net_profit,
        item_sk
    FROM all_data ad
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory i0
        WHERE i0.inv_item_sk = ad.item_sk
          AND i0.inv_quantity_on_hand = 0
    )
)
SELECT
    year,
    store_name,
    department,
    source,
    SUM(net_profit) AS total_net_profit
FROM (
    SELECT
        cs_year AS year,
        s_store_name AS store_name,
        cp_department AS department,
        'catalog' AS source,
        catalog_net_profit AS net_profit
    FROM filtered_data

    UNION ALL

    SELECT
        ss_year AS year,
        s_store_name AS store_name,
        cp_department AS department,
        'store' AS source,
        store_net_profit AS net_profit
    FROM filtered_data
) AS combined
GROUP BY year, store_name, department, source
ORDER BY year DESC, store_name, department, source
