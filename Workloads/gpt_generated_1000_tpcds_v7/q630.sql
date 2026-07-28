WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_brand,
        hd.hd_buy_potential,
        cs.cs_ext_sales_price            AS cs_sales,
        ss.ss_ext_sales_price            AS ss_sales,
        ws.ws_ext_sales_price            AS ws_sales,
        inv.inv_quantity_on_hand         AS inv_qty,
        ca.ca_state,
        sm.sm_contract,
        p.p_discount_active,
        cp.cp_department,
        cs.cs_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = cs.cs_bill_addr_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND i.i_brand = 'Brand#12'
      AND inv.inv_quantity_on_hand > 100
      AND sm.sm_contract = 'hGoF18SLDDPBj'
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
      AND cs.cs_quantity > 1
),
aggregated AS (
    SELECT
        d_year,
        i_brand,
        SUM(cs_sales)                               AS total_cs_sales,
        SUM(ss_sales)                               AS total_ss_sales,
        SUM(ws_sales)                               AS total_ws_sales,
        SUM(inv_qty)                                AS total_inv_qty,
        SUM(cs_sales + ss_sales + ws_sales)         AS total_sales
    FROM joined_data
    GROUP BY d_year, i_brand
)
SELECT
    d_year,
    AVG(total_sales) AS avg_total_sales
FROM aggregated
GROUP BY d_year
HAVING AVG(total_sales) > 10000
