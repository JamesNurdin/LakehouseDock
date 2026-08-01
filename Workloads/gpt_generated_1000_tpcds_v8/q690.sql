WITH
    inventory_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    ),
    intersect_items AS (
        SELECT i_item_sk FROM (
            SELECT cr.cr_item_sk AS i_item_sk
            FROM catalog_returns cr
            JOIN item i ON cr.cr_item_sk = i.i_item_sk
            WHERE cr.cr_return_amount > 500
        )
        INTERSECT
        SELECT i_item_sk FROM (
            SELECT wr.wr_item_sk AS i_item_sk
            FROM web_returns wr
            JOIN item i ON wr.wr_item_sk = i.i_item_sk
            WHERE wr.wr_return_amt > 300
        )
    ),
    union_customers AS (
        SELECT sr.sr_customer_sk AS c_customer_sk FROM store_returns sr
        UNION
        SELECT wr.wr_refunded_customer_sk AS c_customer_sk FROM web_returns wr
    ),
    filtered AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_item_sk,
            cr.cr_refunded_customer_sk,
            cr.cr_refunded_cdemo_sk,
            cr.cr_refunded_hdemo_sk,
            cr.cr_refunded_addr_sk,
            cr.cr_return_amount,
            cr.cr_order_number,
            i.i_current_price,
            i.i_category,
            ca.ca_state,
            r.r_reason_desc,
            td.t_hour,
            ib.ib_lower_bound,
            inv_agg.total_qty_on_hand,
            ROW_NUMBER() OVER (PARTITION BY cr.cr_refunded_customer_sk ORDER BY cr.cr_returned_date_sk DESC) AS rn
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        CROSS JOIN LATERAL (
            SELECT total_qty_on_hand
            FROM inventory_agg ia
            WHERE ia.inv_item_sk = i.i_item_sk
        ) AS inv_agg
        WHERE i.i_current_price BETWEEN 10 AND 50
          AND ca.ca_state = 'CA'
          AND cr.cr_return_amount > 1000
          AND cd.cd_gender = 'M'
    )
SELECT
    f.cr_refunded_customer_sk,
    c.c_first_name,
    c.c_last_name,
    f.i_category,
    SUM(f.cr_return_amount) AS total_return_amount,
    AVG(f.i_current_price) AS avg_item_price,
    MIN(f.total_qty_on_hand) AS min_qty_on_hand,
    COUNT(DISTINCT f.r_reason_desc) AS distinct_reasons,
    MAX(f.t_hour) AS latest_return_hour,
    MAX(f.rn) AS max_rn
FROM filtered f
JOIN customer c ON f.cr_refunded_customer_sk = c.c_customer_sk
JOIN union_customers uc ON c.c_customer_sk = uc.c_customer_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_link_count > 10
    AND wp.wp_rec_end_date > DATE '2000-01-01'
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = f.cr_order_number
    )
  AND f.cr_item_sk IN (SELECT i_item_sk FROM intersect_items)
GROUP BY
    f.cr_refunded_customer_sk,
    c.c_first_name,
    c.c_last_name,
    f.i_category,
    f.rn
ORDER BY total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
