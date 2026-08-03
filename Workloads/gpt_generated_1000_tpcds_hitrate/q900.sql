WITH avg_loss AS (
    SELECT s.s_store_sk,
           AVG(sr.sr_net_loss) AS avg_net_loss
    FROM store_returns sr
    RIGHT OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_sk
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    sr_return_quantity,
    sr_return_amt,
    sr_net_loss,
    avg_net_loss,
    rn,
    loss_category
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        al.avg_net_loss,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.sr_return_amt DESC) AS rn,
        CASE WHEN sr.sr_net_loss > al.avg_net_loss THEN 'Above Avg' ELSE 'Below Avg' END AS loss_category
    FROM store_returns sr
    RIGHT OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN avg_loss al
        ON s.s_store_sk = al.s_store_sk
    WHERE
        s.s_manager = 'Joe Johnson'
        AND s.s_floor_space > 2000
        AND s.s_number_employees BETWEEN 50 AND 200
        AND sr.sr_net_loss > 500
        AND sr.sr_refunded_cash < 100
        AND sr.sr_return_quantity >= 1
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        al.avg_net_loss,
        s.s_store_id
    HAVING COUNT(sr.sr_ticket_number) > 2

    UNION DISTINCT

    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        al.avg_net_loss,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.sr_return_amt ASC) AS rn,
        CASE WHEN sr.sr_net_loss > al.avg_net_loss THEN 'Above Avg' ELSE 'Below Avg' END AS loss_category
    FROM store_returns sr
    RIGHT OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN avg_loss al
        ON s.s_store_sk = al.s_store_sk
    WHERE
        s.s_manager = 'Wayne Coleman'
        AND s.s_floor_space < 5000
        AND s.s_number_employees > 150
        AND sr.sr_net_loss BETWEEN 100 AND 500
        AND sr.sr_refunded_cash > 200
        AND sr.sr_return_quantity = 1
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        al.avg_net_loss,
        s.s_store_id
    HAVING COUNT(*) > 1
) t
ORDER BY loss_category, rn
LIMIT 100
