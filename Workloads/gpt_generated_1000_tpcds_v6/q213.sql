WITH catalog_filtered AS (
    SELECT
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_return_quantity AS qty,
        cr.cr_net_loss AS net_loss,
        cd.cd_gender AS gender,
        cd.cd_education_status AS education,
        td.t_hour AS hour,
        td.t_time_id AS time_id,
        hd.hd_buy_potential AS buy_potential
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(td.t_time_id, '^A{5}C')
      AND cd.cd_education_status LIKE '%Degree%'
      AND hd.hd_buy_potential LIKE '%Potential%'
)
SELECT
    cf.hour,
    cf.gender,
    COUNT(*) AS return_cnt,
    SUM(cf.qty) AS total_qty,
    SUM(cf.net_loss) AS total_net_loss,
    MIN(regexp_extract(cf.time_id, '(C[A-Z]+)', 1)) AS sample_code,
    (
        SELECT AVG(wr.wr_net_loss)
        FROM web_returns wr
        JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
        WHERE td2.t_hour = cf.hour
    ) AS avg_web_net_loss
FROM catalog_filtered cf
GROUP BY cf.hour, cf.gender
HAVING SUM(cf.net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
