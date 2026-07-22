WITH cr_sub AS (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        r_cr.r_reason_desc,
        td_cr.t_hour,
        td_cr.t_minute,
        ROW_NUMBER() OVER (PARTITION BY r_cr.r_reason_desc ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451300 AND 2452150
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND td_cr.t_hour BETWEEN 8 AND 17
      AND r_cr.r_reason_desc IN ('Customer Not Satisfied', 'Damaged Item')
      AND cr.cr_return_amount > (
          SELECT AVG(cr_return_amount)
          FROM catalog_returns
          WHERE cr_returned_date_sk BETWEEN 2451300 AND 2452150
      )
),
sr_sub AS (
    SELECT
        sr.sr_ticket_number AS order_number,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        r_sr.r_reason_desc,
        td_sr.t_hour,
        td_sr.t_minute,
        ROW_NUMBER() OVER (PARTITION BY r_sr.r_reason_desc ORDER BY sr.sr_return_amt DESC) AS rn
    FROM store_returns sr
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451300 AND 2452150
      AND sr.sr_return_amt > 100
      AND sr.sr_return_quantity >= 1
      AND td_sr.t_hour BETWEEN 8 AND 17
      AND r_sr.r_reason_desc IN ('Customer Not Satisfied', 'Damaged Item')
),
wr_sub AS (
    SELECT
        wr.wr_order_number AS order_number,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        r_wr.r_reason_desc,
        td_wr.t_hour,
        td_wr.t_minute,
        ROW_NUMBER() OVER (PARTITION BY r_wr.r_reason_desc ORDER BY wr.wr_return_amt DESC) AS rn
    FROM web_returns wr
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451300 AND 2452150
      AND wr.wr_return_amt > 100
      AND wr.wr_return_quantity >= 1
      AND td_wr.t_hour BETWEEN 8 AND 17
      AND r_wr.r_reason_desc IN ('Customer Not Satisfied', 'Damaged Item')
)
SELECT
    order_number,
    return_amount,
    net_loss,
    CASE
        WHEN net_loss >= 500 THEN 'High'
        WHEN net_loss >= 200 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    r_reason_desc,
    t_hour,
    t_minute,
    rn
FROM (
    SELECT order_number, return_amount, net_loss, r_reason_desc, t_hour, t_minute, rn
    FROM cr_sub
    UNION ALL
    SELECT order_number, return_amount, net_loss, r_reason_desc, t_hour, t_minute, rn
    FROM sr_sub
    UNION ALL
    SELECT order_number, return_amount, net_loss, r_reason_desc, t_hour, t_minute, rn
    FROM wr_sub
) combined
WHERE rn <= 10
ORDER BY net_loss DESC
LIMIT 100
