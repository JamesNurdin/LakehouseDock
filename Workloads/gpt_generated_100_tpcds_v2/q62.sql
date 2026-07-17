WITH store_warehouse AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_rec_start_date,
        w.w_warehouse_id,
        w.w_zip,
        CONCAT(s.s_city, ', ', s.s_state) AS store_location,
        SUBSTRING(w.w_zip, 1, 2) AS zip_prefix
    FROM tpcds.store s
    JOIN tpcds.warehouse w
        ON s.s_city = w.w_city
    WHERE s.s_store_name LIKE 'c%'
      AND w.w_zip LIKE '44%'
      AND s.s_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
)
SELECT
    sw.s_store_id,
    sw.s_store_name,
    sw.w_warehouse_id,
    sw.store_location,
    sw.zip_prefix,
    COALESCE(wr.total_net_loss, 0) AS total_net_loss
FROM store_warehouse sw
LEFT JOIN (
    SELECT SUM(wr.wr_net_loss) AS total_net_loss
    FROM tpcds.web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2451349 AND 2452376
) wr
    ON TRUE
ORDER BY sw.s_store_id
LIMIT 100
