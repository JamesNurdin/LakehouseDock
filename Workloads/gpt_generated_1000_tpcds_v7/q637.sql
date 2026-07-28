WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        c.c_customer_sk,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_net_loss AS catalog_net_loss,
        wr.wr_net_loss AS web_net_loss,
        r.r_reason_desc,
        cc.cc_company_name,
        cp.cp_type,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
)
SELECT
    d_year,
    c_customer_sk,
    cc_company_name,
    ca_city,
    SUM(store_net_loss) AS total_store_loss,
    SUM(catalog_net_loss) AS total_catalog_loss,
    SUM(web_net_loss) AS total_web_loss,
    SUM(store_net_loss + catalog_net_loss + web_net_loss) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(store_net_loss + catalog_net_loss + web_net_loss) DESC) AS loss_rank,
    CASE
        WHEN SUM(store_net_loss + catalog_net_loss + web_net_loss) > 10000 THEN 'High'
        WHEN SUM(store_net_loss + catalog_net_loss + web_net_loss) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category
FROM base
WHERE
    d_year BETWEEN 2000 AND 2002
    AND r_reason_desc LIKE '%damaged%'
    AND cc_company_name = 'anti'
GROUP BY
    d_year,
    c_customer_sk,
    cc_company_name,
    ca_city
ORDER BY total_loss DESC
LIMIT 100
