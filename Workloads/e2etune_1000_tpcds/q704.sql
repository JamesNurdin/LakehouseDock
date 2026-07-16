WITH returns_joined AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_type AS type,
        cp.cp_catalog_page_id AS catalog_page_id,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_returned_date_sk AS returned_date_sk,
        cp.cp_start_date_sk AS start_date_sk,
        cp.cp_end_date_sk AS end_date_sk
    FROM catalog_page cp
    JOIN web_returns wr
        ON wr.wr_web_page_sk = cp.cp_catalog_page_sk
        AND wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk >= 2450800
      AND cp.cp_end_date_sk <= 2451100
),
aggregated AS (
    SELECT
        department,
        type,
        COUNT(DISTINCT catalog_page_id) AS num_pages,
        SUM(return_amt) AS total_return_amount,
        SUM(net_loss) AS total_net_loss,
        AVG(return_quantity) AS avg_return_qty,
        COUNT(*) AS total_returns
    FROM returns_joined
    GROUP BY department, type
    HAVING SUM(return_amt) > 10000
)
SELECT
    department,
    type,
    num_pages,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    total_returns,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 10
