/*
Goal: Calculate total and average net loss of catalog returns per income‑band for customers whose current city starts with “San” or “New” and whose returned item description contains a three‑digit code. The query also counts the distinct three‑digit codes extracted from the item description.
*/
WITH joined AS (
    SELECT
        cr.cr_net_loss,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '([0-9]{3})', 1) AS item_code,
        ca.ca_city
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(ca.ca_city, '^San|^New')
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
)
SELECT
    CONCAT(CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) AS income_range,
    COUNT(DISTINCT item_code) AS distinct_item_codes,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_net_loss) AS avg_net_loss
FROM joined
GROUP BY ib_lower_bound, ib_upper_bound
ORDER BY total_net_loss DESC
LIMIT 10
