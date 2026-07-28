WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        i.i_current_price,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        wr.wr_fee,
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        inv.inv_quantity_on_hand,
        wp.wp_autogen_flag,
        wp.wp_image_count,
        ws.web_name
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.i_category_id IN (1, 4, 9)
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND wp.wp_autogen_flag = 'Y'
      AND ws.web_name LIKE '%Online%'
      AND inv.inv_quantity_on_hand > 0
),
agg1 AS (
    SELECT
        d_year,
        i_category,
        i_category_id,
        SUM(wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        AVG(inv_quantity_on_hand) AS avg_inventory_qty,
        CASE WHEN SUM(wr_return_amt_inc_tax) > 5000 THEN 'HIGH' ELSE 'LOW' END AS return_level
    FROM joined_data
    GROUP BY d_year, i_category, i_category_id
),
final AS (
    SELECT
        d_year,
        i_category,
        i_category_id,
        total_return_amt,
        distinct_customers,
        avg_inventory_qty,
        return_level,
        RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank,
        SUM(total_return_amt) OVER () AS overall_total_return
    FROM agg1
)
SELECT
    d_year,
    i_category,
    i_category_id,
    total_return_amt,
    distinct_customers,
    avg_inventory_qty,
    return_level,
    return_rank,
    overall_total_return
FROM final
WHERE return_rank <= 10
ORDER BY total_return_amt DESC
LIMIT 100
