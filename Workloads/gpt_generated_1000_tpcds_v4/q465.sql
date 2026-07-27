WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        d1.d_year,
        d1.d_month_seq,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ca.ca_state,
        cp.cp_department,
        wp.wp_type,
        w.w_warehouse_id,
        inv.inv_quantity_on_hand,
        (
            SELECT avg(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
        ) AS avg_item_return_amt
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d1.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                     AND wp.wp_creation_date_sk = d1.d_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_date_sk = d1.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d1.d_year = 2001
      AND i.i_current_price > 50
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 1
      AND ca.ca_state = 'CA'
      AND cp.cp_department = 'Books'
      AND wp.wp_type = 'Home'
)
SELECT
    d_year,
    c_customer_id,
    c_first_name,
    c_last_name,
    i_item_id,
    i_brand,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_return_quantity) AS total_return_qty,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(avg_item_return_amt) AS avg_return_amt_per_item,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(sr_return_amt) DESC) AS yearly_customer_rank
FROM base
GROUP BY d_year, c_customer_id, c_first_name, c_last_name, i_item_id, i_brand
HAVING SUM(sr_return_amt) > 1000
ORDER BY d_year, yearly_customer_rank
LIMIT 100
