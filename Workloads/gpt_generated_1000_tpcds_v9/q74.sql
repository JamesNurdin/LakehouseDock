WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        i.i_brand_id AS brand_id,
        d.d_year AS year,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        AVG(ib.ib_lower_bound) AS avg_income_lower,
        AVG(ib.ib_upper_bound) AS avg_income_upper,
        MAX(p.p_cost) AS max_promo_cost
    FROM
        item i
        INNER JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        INNER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
        LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        INNER JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_date >= DATE '2001-01-01'
        AND d.d_date <= DATE '2002-12-31'
        AND i.i_brand_id IN (1, 2, 3)
        AND ss.ss_quantity > 10
        AND cs.cs_sales_price > 20
        AND hd.hd_vehicle_count >= 1
        AND EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk AND p2.p_cost > 100
        )
    GROUP BY
        i.i_brand,
        i.i_brand_id,
        d.d_year
)

SELECT DISTINCT
    brand,
    year,
    distinct_customers,
    total_profit,
    avg_income_lower,
    avg_income_upper,
    max_promo_cost,
    rank
FROM (
    SELECT
        brand,
        year,
        distinct_customers,
        (store_net_profit + catalog_net_profit) AS total_profit,
        avg_income_lower,
        avg_income_upper,
        max_promo_cost,
        ROW_NUMBER() OVER (PARTITION BY brand ORDER BY (store_net_profit + catalog_net_profit) DESC) AS rank
    FROM sales_agg
) ranked
WHERE rank <= 5
ORDER BY total_profit DESC
LIMIT 100
