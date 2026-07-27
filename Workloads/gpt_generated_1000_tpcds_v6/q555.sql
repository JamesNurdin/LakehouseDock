/*
  Goal: Identify the top‑ranking product‑return scenarios for the year 2001 where returns were due to damaged items,
  filtered by specific department, promotion activity, customer states, and web‑page type.  The query aggregates inventory
  quantities in a CTE, joins all eight selected tables using only the permitted join keys, applies multiple filter
  predicates, filters aggregated groups with HAVING, computes a stock‑category flag, ranks results per year by total
  return amount, orders the final rows, and limits the output to the top 100 records.
*/
WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
joined_data AS (
    SELECT
        d_wr.d_year,
        cp.cp_department,
        p.p_promo_name,
        r.r_reason_desc,
        ca_refunded.ca_state   AS refunded_state,
        ca_returning.ca_state  AS returning_state,
        wp.wp_type,
        inv_agg.total_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*)               AS return_cnt
    FROM inv_agg
    JOIN date_dim d_inv
        ON inv_agg.inv_date_sk = d_inv.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_inv.d_date_sk
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_wr.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_wr.d_date_sk
    WHERE
        d_wr.d_year = 2001
        AND cp.cp_department = 'Books'
        AND p.p_discount_active = 'Y'
        AND r.r_reason_desc LIKE '%damaged%'
        AND ca_refunded.ca_state = 'CA'
        AND ca_returning.ca_state = 'TX'
        AND wp.wp_type = 'home'
        AND d_wr.d_week_seq IN (12, 18)
    GROUP BY
        d_wr.d_year,
        cp.cp_department,
        p.p_promo_name,
        r.r_reason_desc,
        ca_refunded.ca_state,
        ca_returning.ca_state,
        wp.wp_type,
        inv_agg.total_qty
    HAVING
        SUM(wr.wr_return_amt) > 1000
        AND COUNT(*) > 5
)
SELECT
    d_year,
    cp_department,
    p_promo_name,
    r_reason_desc,
    refunded_state,
    returning_state,
    wp_type,
    total_qty,
    total_return_amt,
    return_cnt,
    CASE WHEN total_qty > 1000 THEN 'High Stock' ELSE 'Low Stock' END AS stock_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS sales_rank
FROM joined_data
ORDER BY sales_rank, total_return_amt DESC
LIMIT 100
