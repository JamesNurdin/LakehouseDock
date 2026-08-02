WITH
    -- Combine catalog and web returns (distinct UNION)
    union_returns AS (
        SELECT
            cr_returned_date_sk AS date_sk,
            cr_returning_cdemo_sk AS cdemo_sk,
            cr_return_amount AS return_amount,
            cr_net_loss AS net_loss
        FROM catalog_returns
        UNION
        SELECT
            wr_returned_date_sk AS date_sk,
            wr_refunded_cdemo_sk AS cdemo_sk,
            wr_return_amt AS return_amount,
            wr_net_loss AS net_loss
        FROM web_returns
    ),
    -- Dates that have both high inventory and a positive store return loss
    intersect_dates AS (
        SELECT DISTINCT inv_date_sk AS date_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 5000
        INTERSECT
        SELECT DISTINCT sr_returned_date_sk AS date_sk
        FROM store_returns
        WHERE sr_net_loss > 0
    ),
    -- Aggregate return metrics per year/month/site/gender
    base_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            ws.web_site_id,
            cd.cd_gender,
            SUM(ur.return_amount) AS total_return_amount,
            SUM(ur.net_loss) AS total_net_loss,
            COUNT(DISTINCT ur.date_sk) AS distinct_return_dates
        FROM union_returns ur
        JOIN date_dim d
            ON ur.date_sk = d.d_date_sk
        JOIN customer_demographics cd
            ON ur.cdemo_sk = cd.cd_demo_sk
        JOIN web_site ws
            ON ws.web_open_date_sk = d.d_date_sk
        JOIN inventory inv
            ON inv.inv_date_sk = d.d_date_sk
        JOIN store_returns sr
            ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_fy_year IN (1914, 1919)
          AND d.d_weekend = 'N'
          AND ws.web_suite_number = 'Suite 210'
          AND inv.inv_warehouse_sk = 9
          AND d.d_date BETWEEN DATE '2012-01-01' AND DATE '2012-12-31'
          AND ur.date_sk IN (SELECT date_sk FROM intersect_dates)
          AND EXISTS (
                SELECT 1
                FROM web_site ws2
                WHERE ws2.web_site_id = ws.web_site_id
                  AND ws2.web_mkt_desc LIKE '%police%'
          )
        GROUP BY
            d.d_year,
            d.d_month_seq,
            ws.web_site_id,
            cd.cd_gender
    ),
    -- Count of distinct inventory items with very high on‑hand quantity
    high_inventory_items AS (
        SELECT DISTINCT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 10000
    )
SELECT
    b.d_year,
    b.d_month_seq,
    b.web_site_id,
    b.cd_gender,
    b.total_return_amount,
    b.total_net_loss,
    b.distinct_return_dates,
    SUM(b.total_return_amount) OVER (
        PARTITION BY b.d_year
        ORDER BY b.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_amount_year,
    RANK() OVER (
        PARTITION BY b.d_year
        ORDER BY b.total_net_loss DESC
    ) AS net_loss_rank,
    (SELECT COUNT(*) FROM high_inventory_items) AS high_inventory_item_count
FROM base_agg b
ORDER BY
    b.total_net_loss DESC,
    b.d_year,
    b.d_month_seq
LIMIT 100
