WITH
    catalog_agg AS (
        SELECT
            i.i_category,
            i.i_brand,
            hd_bill.hd_buy_potential,
            ib.ib_upper_bound,
            d_sold.d_year,
            SUM(cs.cs_net_profit) AS total_catalog_profit,
            COUNT(DISTINCT c_bill.c_customer_id) AS distinct_billing_customers,
            COUNT(DISTINCT c_ship.c_customer_id) AS distinct_shipping_customers,
            COUNT(DISTINCT ca_ship.ca_city) AS distinct_shipping_cities,
            SUM(cs.cs_quantity) AS total_units_sold
        FROM catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        WHERE d_sold.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        GROUP BY
            i.i_category,
            i.i_brand,
            hd_bill.hd_buy_potential,
            ib.ib_upper_bound,
            d_sold.d_year
    ),
    web_agg AS (
        SELECT
            i_ws.i_category,
            i_ws.i_brand,
            SUM(ws.ws_net_profit) AS total_web_profit,
            SUM(ws.ws_ext_sales_price) AS total_web_sales,
            COUNT(DISTINCT wp.wp_url) AS distinct_web_pages
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE d_ws.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        GROUP BY i_ws.i_category, i_ws.i_brand
    ),
    store_return_agg AS (
        SELECT
            i_sr.i_category,
            i_sr.i_brand,
            SUM(sr.sr_net_loss) AS total_store_return_loss,
            COUNT(DISTINCT s.s_store_id) AS distinct_stores,
            COUNT(DISTINCT c_sr.c_customer_id) AS distinct_return_customers,
            COUNT(DISTINCT hd_sr.hd_income_band_sk) AS distinct_return_income_bands,
            COUNT(DISTINCT ca_sr.ca_city) AS distinct_return_cities
        FROM store_returns sr
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        WHERE d_sr.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        GROUP BY i_sr.i_category, i_sr.i_brand
    ),
    web_return_agg AS (
        SELECT
            i_wr.i_category,
            i_wr.i_brand,
            SUM(wr.wr_net_loss) AS total_web_return_loss,
            COUNT(DISTINCT wp2.wp_web_page_sk) AS distinct_return_pages,
            COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_refunded_customers
        FROM web_returns wr
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
        JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
        WHERE d_wr.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        GROUP BY i_wr.i_category, i_wr.i_brand
    ),
    inventory_agg AS (
        SELECT
            i_inv.i_category,
            i_inv.i_brand,
            SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
        FROM inventory inv
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN item i_inv ON inv.inv_item_sk = i_inv.i_item_sk
        WHERE d_inv.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        GROUP BY i_inv.i_category, i_inv.i_brand
    )
SELECT
    ca.i_category,
    ca.i_brand,
    ca.hd_buy_potential,
    ca.ib_upper_bound,
    ca.d_year,
    ca.total_catalog_profit,
    ca.distinct_billing_customers,
    ca.distinct_shipping_customers,
    ca.distinct_shipping_cities,
    ca.total_units_sold,
    wa.total_web_profit,
    wa.total_web_sales,
    wa.distinct_web_pages,
    sra.total_store_return_loss,
    sra.distinct_stores,
    sra.distinct_return_customers,
    sra.distinct_return_income_bands,
    sra.distinct_return_cities,
    wra.total_web_return_loss,
    wra.distinct_return_pages,
    wra.distinct_refunded_customers,
    ia.total_inventory_qty,
    ROW_NUMBER() OVER (ORDER BY ca.total_catalog_profit DESC) AS profit_rank,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_sales ws_check
            JOIN date_dim d_check ON ws_check.ws_sold_date_sk = d_check.d_date_sk
            WHERE ws_check.ws_item_sk = i.i_item_sk
              AND d_check.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
              AND ws_check.ws_ext_sales_price > 5000
        ) THEN 'High'
        ELSE 'Normal'
    END AS sales_category_flag
FROM catalog_agg ca
LEFT JOIN web_agg wa ON ca.i_category = wa.i_category AND ca.i_brand = wa.i_brand
LEFT JOIN store_return_agg sra ON ca.i_category = sra.i_category AND ca.i_brand = sra.i_brand
LEFT JOIN web_return_agg wra ON ca.i_category = wra.i_category AND ca.i_brand = wra.i_brand
LEFT JOIN inventory_agg ia ON ca.i_category = ia.i_category AND ca.i_brand = ia.i_brand
JOIN item i ON i.i_category = ca.i_category AND i.i_brand = ca.i_brand
WHERE ca.total_catalog_profit > 0
ORDER BY ca.total_catalog_profit DESC
LIMIT 100
