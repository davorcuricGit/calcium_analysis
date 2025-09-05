function B = moving_average_overlap(A, m, overlap)
    % A: N x T array
    % m: window size
    % overlap: fraction (0 to <1), e.g. 0.5 = 50% overlap
    % B: N x t array (moving averages with specified overlap)

    [N, T] = size(A);

    % Step size (round to integer index shift)
    step = max(1, round(m * (1 - overlap)));

    % Number of windows that fit
    num_windows = floor((T - m)/step) + 1;

    B = zeros(N, num_windows);

    for w = 1:num_windows
        start_idx = (w-1)*step + 1;
        stop_idx = start_idx + m - 1;
        B(:, w) = mean(A(:, start_idx:stop_idx), 2);
    end
end
