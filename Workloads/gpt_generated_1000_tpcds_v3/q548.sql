WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cp.cp_department,
        i.i_item_sk,
        w.w_warehouse_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        (SELECT COALESCE(SUM(wr.wr_net_loss), 0)
         FROM web_returns wr
         WHERE wr.wr_item_sk = i.i_item_sk
           AND wr.wr_refunded_customer_sk = c.c_customer_sk) AS total_web_return_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM store_sales ss
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE i.i_current_price > 50
      AND c.c_birth_month = 5
      AND ca.ca_state = 'CA'
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_upper_bound > 50000
      AND cp.cp_department = 'Electronics'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
              AND wr.wr_refunded_customer_sk = c.c_customer_sk
              AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
          )
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cp.cp_department,
        i.i_item_sk,
        w.w_warehouse_sk
    HAVING SUM(ss.ss_ext_sales_price) > 1000
       AND SUM(inv.inv_quantity_on_hand) > 0
)
SELECT
    b.c_customer_id,
    b.c_first_name,
    b.c_last_name,
    b.cp_department,
    b.total_sales,
    b.total_catalog_return_loss,
    b.total_store_return_loss,
    b.total_web_return_loss,
    (b.total_catalog_return_loss + b.total_store_return_loss + b.total_web_return_loss) AS total_net_loss,
    b.total_inventory_on_hand,
    RANK() OVER (PARTITION BY b.cp_department ORDER BY (b.total_catalog_return_loss + b.total_store_return_loss + b.total_web_return_loss) DESC) AS dept_net_loss_rank
FROM base b
WHERE b.total_inventory_on_hand >= 10
ORDER BY b.cp_department, dept_net_loss_rank
LIMIT 100
