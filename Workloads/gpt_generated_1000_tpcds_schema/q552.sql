WITH
    sampled_item AS (
        SELECT *
        FROM item
        TABLESAMPLE BERNOULLI (10)
    ),
    base AS (
        SELECT
            d.d_year,
            i.i_item_id,
            i.i_category,
            i.i_brand,
            c.c_customer_id,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            cp.cp_department,
            sm.sm_type,
            s.s_store_name,
            s.s_state,
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_paid,
            cr.cr_return_quantity,
            ws.ws_quantity,
            ws.ws_net_paid,
            wr.wr_return_quantity,
            wr.wr_net_loss,
            r.r_reason_desc
        FROM date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN sampled_item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
            AND cs.cs_item_sk = i.i_item_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_brand = 'Brand#45'
          AND s.s_state = 'CA'
          AND sm.sm_type = 'AIR'
          AND ib.ib_lower_bound >= 50000
          AND cp.cp_department = 'Books'
    ),
    agg AS (
        SELECT
            d_year,
            i_category,
            s_state,
            SUM(cs_net_paid) AS total_sales,
            SUM(ws_net_paid) AS total_web_sales,
            COUNT(DISTINCT cs_order_number) AS num_orders
        FROM base
        GROUP BY d_year, i_category, s_state
        HAVING SUM(cs_net_paid) > 10000
    ),
    intersect_orders AS (
        SELECT cs_order_number AS order_num
        FROM catalog_sales
        WHERE cs_quantity > 5
        INTERSECT
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_quantity > 5
    ),
    anti AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_order_number NOT IN (
            SELECT cr_order_number
            FROM catalog_returns
            WHERE cr_return_quantity > 0
        )
    ),
    except_items AS (
        SELECT inv_item_sk
        FROM inventory
        EXCEPT
        SELECT i_item_sk
        FROM item
        WHERE i_current_price > 200
    ),
    full_store AS (
        SELECT ss.ss_sold_date_sk,
               ss.ss_item_sk,
               s.s_store_name,
               s.s_state
        FROM store_sales ss
        FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    )
SELECT
    a.d_year,
    a.i_category,
    a.s_state,
    a.total_sales,
    a.total_web_sales,
    a.num_orders
FROM agg a
WHERE a.d_year = 2001
  AND a.s_state = 'CA'
  AND a.total_sales > (SELECT AVG(total_sales) FROM agg)
  AND a.total_sales > 50000
  AND a.num_orders > 10
  AND a.total_sales > (SELECT COUNT(*) FROM intersect_orders)
  AND EXISTS (SELECT 1 FROM anti ant WHERE ant.cs_order_number = (SELECT MIN(cs_order_number) FROM catalog_sales))
  AND EXISTS (SELECT 1 FROM except_items ei)
ORDER BY a.total_sales DESC
LIMIT 100
