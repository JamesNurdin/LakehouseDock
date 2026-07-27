WITH returns_demo AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        d.d_day_name,
        d.d_current_month
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(d.d_day_name, '^S')               -- days that start with S (Saturday, Sunday)
      AND hd.hd_buy_potential LIKE '%1000%'
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    regexp_extract(cp.cp_description, '(\\d{3,})') AS numeric_code,
    CONCAT(cp.cp_type, '-', cp.cp_department) AS type_dept,
    rd.hd_buy_potential,
    SUM(rd.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM returns_demo rd
JOIN catalog_page cp ON cp.cp_start_date_sk = rd.wr_returned_date_sk
WHERE cp.cp_description LIKE '%sale%'
  AND regexp_like(cp.cp_description, '[A-Z]{3,}')
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    regexp_extract(cp.cp_description, '(\\d{3,})'),
    CONCAT(cp.cp_type, '-', cp.cp_department),
    rd.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
