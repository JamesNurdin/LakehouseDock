WITH sales_data AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        ss.ss_sold_time_sk AS time_sk,
        ss.ss_store_sk AS store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_number_employees > 250
      AND s.s_street_type = 'Boulevard'
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand_id IN (1, 2, 3)
      AND i.i_current_price > 100
    GROUP BY
        ss.ss_item_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk
),
returns_raw AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_return_quantity AS return_qty,
        cr.cr_return_amount AS return_amt,
        cr.cr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE r.r_reason_desc = 'Lost my job'
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand_id IN (1, 2, 3)
),
web_returns_raw AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        wr.wr_returned_time_sk AS time_sk,
        wr.wr_return_quantity AS return_qty,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE r.r_reason_desc = 'Lost my job'
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand_id IN (1, 2, 3)
),
returns_combined AS (
    SELECT * FROM returns_raw
    UNION ALL
    SELECT * FROM web_returns_raw
),
returns_agg AS (
    SELECT
        item_sk,
        time_sk,
        SUM(return_qty) AS total_return_qty,
        SUM(return_amt) AS total_return_amt,
        SUM(net_loss) AS total_return_loss,
        COUNT(DISTINCT reason_desc) AS distinct_reason_cnt
    FROM returns_combined
    GROUP BY
        item_sk,
        time_sk
)
SELECT
    COALESCE(s.s_store_id, 'UNKNOWN') AS store_id,
    COALESCE(s.s_store_name, 'No Store') AS store_name,
    i.i_category AS category,
    i.i_brand AS brand,
    SUM(COALESCE(sd.total_net_paid, 0)) AS sum_net_paid,
    SUM(COALESCE(sd.total_net_profit, 0)) AS sum_net_profit,
    SUM(COALESCE(ra.total_return_qty, 0)) AS sum_return_qty,
    SUM(COALESCE(ra.total_return_amt, 0)) AS sum_return_amt,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    CASE
        WHEN SUM(COALESCE(sd.total_net_profit, 0)) > 5000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    MAX(ra.distinct_reason_cnt) AS max_distinct_reasons
FROM sales_data sd
FULL OUTER JOIN returns_agg ra
    ON sd.item_sk = ra.item_sk AND sd.time_sk = ra.time_sk
LEFT JOIN store s
    ON sd.store_sk = s.s_store_sk
LEFT JOIN item i
    ON COALESCE(sd.item_sk, ra.item_sk) = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_item_sk = COALESCE(sd.item_sk, ra.item_sk)
      AND wr.wr_return_quantity > 0
)
AND NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = COALESCE(sd.item_sk, ra.item_sk)
      AND cr.cr_return_amount > 500
)
GROUP BY
    COALESCE(s.s_store_id, 'UNKNOWN'),
    COALESCE(s.s_store_name, 'No Store'),
    i.i_category,
    i.i_brand
ORDER BY
    store_name ASC,
    sum_net_profit DESC
