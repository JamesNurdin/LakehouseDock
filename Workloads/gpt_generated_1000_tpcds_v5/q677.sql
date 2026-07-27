WITH filtered_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date,
        cd.cd_gender,
        cd.cd_education_status,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        sr.sr_net_loss,
        sr.sr_store_credit,
        wr.wr_net_loss,
        ws.web_tax_percentage,
        ws.web_zip
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND d.d_date = DATE '2001-01-15'
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
      AND inv.inv_warehouse_sk = 10
      AND ws.web_zip = '48059'
      AND ws.web_tax_percentage > 0.05
      AND sr.sr_net_loss > 500
), max_tax_per_zip AS (
    SELECT web_zip, MAX(web_tax_percentage) AS max_tax
    FROM tpcds.web_site
    GROUP BY web_zip
)
SELECT
    fd.d_year,
    fd.d_month_seq,
    fd.cd_gender,
    fd.cd_education_status,
    fd.inv_warehouse_sk,
    COUNT(*) AS return_count,
    SUM(fd.sr_net_loss) AS total_store_loss,
    SUM(fd.wr_net_loss) AS total_web_loss,
    AVG(fd.inv_quantity_on_hand) AS avg_inventory_qty,
    MAX(CASE WHEN fd.sr_store_credit > 1000 THEN fd.sr_store_credit END) AS max_high_store_credit,
    (SELECT max_tax FROM max_tax_per_zip mt WHERE mt.web_zip = fd.web_zip) AS max_tax_for_zip
FROM filtered_data fd
GROUP BY
    fd.d_year,
    fd.d_month_seq,
    fd.cd_gender,
    fd.cd_education_status,
    fd.inv_warehouse_sk,
    fd.web_zip
HAVING COUNT(*) > 10
ORDER BY total_store_loss DESC
LIMIT 100
