/* Goal: Identify the most valuable product brands for store returns in 2001, broken down by customer education level and return amount category, using a chain of joins across all eight TPC‑DS tables. */
WITH joined AS (
    SELECT
        d.d_year,
        i.i_brand,
        cd.cd_education_status,
        CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_category,
        sr.sr_return_amt,
        sr.sr_net_loss,
        i.i_current_price,
        r.r_reason_desc,
        hd.hd_vehicle_count,
        cd.cd_gender,
        ws.web_tax_percentage,
        ws.web_name
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                   -- filter 1: specific year
      AND i.i_current_price > 50                            -- filter 2: price threshold
      AND r.r_reason_desc LIKE '%price%'                    -- filter 3: reason containing "price"
      AND hd.hd_vehicle_count >= 2                         -- filter 4: households with ≥2 vehicles
      AND ws.web_tax_percentage <= 0.05                    -- filter 5: low web tax sites
      AND cd.cd_gender = 'M'                                -- filter 6: male customers
),
agg AS (
    SELECT
        d_year,
        i_brand,
        cd_education_status,
        return_category,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM joined
    GROUP BY d_year, i_brand, cd_education_status, return_category
)
SELECT DISTINCT
    d_year,
    i_brand,
    cd_education_status,
    return_category,
    total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_return_amt DESC) AS brand_return_rank
FROM agg
ORDER BY d_year DESC, total_return_amt DESC
LIMIT 100
