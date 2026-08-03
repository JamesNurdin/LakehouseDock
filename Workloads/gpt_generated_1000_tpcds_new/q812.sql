WITH orders_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
),
agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        AVG(cs.cs_quantity) AS avg_qty,
        MIN(cs.cs_sales_price) AS min_price,
        MAX(cs.cs_sales_price) AS max_price,
        (SELECT AVG(cd_purchase_estimate) FROM customer_demographics) AS avg_purchase_est
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
                      AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
                      AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    WHERE d.d_year = 2002
      AND cd.cd_purchase_estimate > 8000
      AND ib.ib_lower_bound >= 50000
      AND i.i_brand = 'Brand#12'
      AND cc.cc_gmt_offset = -5.00
      AND cs.cs_item_sk NOT IN (SELECT i_item_sk FROM item WHERE i_category = 'Obsolete')
      AND cs.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
    GROUP BY s.s_store_name, i.i_category, d.d_year
)
SELECT
    rn,
    s_store_name,
    i_category,
    d_year,
    total_net_paid,
    orders_cnt,
    avg_qty,
    min_price,
    max_price,
    avg_purchase_est
FROM (
    SELECT
        ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn,
        *
    FROM agg
) t
ORDER BY rn
OFFSET 0 FETCH NEXT 100 ROWS ONLY
