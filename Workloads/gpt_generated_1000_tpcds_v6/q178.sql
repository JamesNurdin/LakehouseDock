WITH sales_agg AS (
    SELECT
        i.i_manufact_id,
        i.i_brand,
        i.i_category,
        t.t_hour,
        t.t_am_pm,
        ca.ca_state,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_manufact_id IN (625, 460, 995)                     -- filter 1
      AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00               -- filter 2
      AND t.t_am_pm = 'PM'                                       -- filter 3
      AND t.t_minute IN (4, 10, 12)                              -- filter 4
      AND i.i_category = 'Furniture'                             -- filter 5
    GROUP BY
        i.i_manufact_id,
        i.i_brand,
        i.i_category,
        t.t_hour,
        t.t_am_pm,
        ca.ca_state
),
returns_agg AS (
    SELECT
        i.i_manufact_id,
        t.t_hour,
        COALESCE(r.r_reason_desc, 'Unknown') AS reason_desc,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_return_amt) AS web_return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE i.i_manufact_id IN (625, 460, 995)          -- filter 1 (same set)
      AND t.t_hour BETWEEN 12 AND 20               -- filter 2
      AND r.r_reason_desc IS NOT NULL              -- filter 3
    GROUP BY
        i.i_manufact_id,
        t.t_hour,
        COALESCE(r.r_reason_desc, 'Unknown')
)
SELECT
    s.i_manufact_id,
    s.i_brand,
    s.i_category,
    s.t_hour,
    s.t_am_pm,
    s.ca_state,
    s.total_quantity_sold,
    s.total_net_paid,
    r.catalog_return_qty,
    r.catalog_return_amount,
    r.web_return_qty,
    r.web_return_amount,
    (s.total_net_paid - COALESCE(r.catalog_return_amount, 0) - COALESCE(r.web_return_amount, 0)) AS net_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_manufact_id = r.i_manufact_id
   AND s.t_hour = r.t_hour
ORDER BY net_after_returns DESC
LIMIT 100
