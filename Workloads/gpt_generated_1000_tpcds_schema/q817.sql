/* goal: Identify high‑value call centers together with their web sites, rank them by net paid amount, expand quantity and tax values as array elements, and show total net paid per call center */
WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_employees,
        cs.cs_quantity,
        cs.cs_ext_tax,
        cs.cs_net_paid,
        cs.cs_call_center_sk,
        dd.d_fy_year,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        sr.sr_return_amt,
        r.r_reason_desc,
        ws.web_site_id,
        ws.web_state,
        wp.wp_web_page_id,
        ARRAY[cs.cs_quantity, CAST(cs.cs_ext_tax AS integer)] AS qty_tax_arr
    FROM call_center cc
    FULL OUTER JOIN catalog_sales cs
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN date_dim dd
        ON cc.cc_open_date_sk = dd.d_date_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = dd.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = dd.d_date_sk
    WHERE
        dd.d_fy_year = 1905
        AND ib.ib_lower_bound >= 50000
        AND cs.cs_ext_tax > 100
        AND cs.cs_quantity BETWEEN 1 AND 5
        AND ws.web_state = 'CA'
        AND cc.cc_employees > 3000000
        AND r.r_reason_id LIKE 'AAAAAAA%'
        AND EXISTS (
            SELECT 1 FROM store_returns sr2
            WHERE sr2.sr_hdemo_sk = hd.hd_demo_sk
              AND sr2.sr_return_amt > 200
        )
)
SELECT
    b.cc_call_center_id,
    b.web_site_id,
    b.web_state,
    b.d_fy_year,
    b.r_reason_desc,
    b.ib_lower_bound,
    b.qty_tax_arr,
    t.val AS array_value,
    b.cs_net_paid,
    (SELECT SUM(cs3.cs_net_paid)
     FROM catalog_sales cs3
     WHERE cs3.cs_call_center_sk = b.cc_call_center_sk) AS total_net_paid_by_cc,
    ROW_NUMBER() OVER (PARTITION BY b.cc_call_center_id ORDER BY b.cs_net_paid DESC) AS rn_per_cc,
    DENSE_RANK() OVER (ORDER BY b.cs_net_paid DESC) AS dr_overall
FROM base b
CROSS JOIN UNNEST(b.qty_tax_arr) AS t(val)
ORDER BY b.cs_net_paid DESC, rn_per_cc
LIMIT 100
